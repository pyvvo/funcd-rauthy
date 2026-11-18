// Compiles the funcd mails (src/*.mjml) into rauthy's askama templates
// (templates/email/<name>.html). `node build.mjs --check` compares instead of
// writing and exits 1 when a committed template is stale.
import mjml2html from 'mjml';
import { readdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const srcDir = path.join(here, 'src');
const outDir = path.join(here, '..', '..', 'templates', 'email');
const check = process.argv.includes('--check');

// askama expressions and tags; every one in a source must survive compilation
const askamaToken = /\{\{.*?\}\}|\{%.*?%\}/gs;

async function withIncludes(file) {
    const text = await readFile(file, 'utf8');
    const parts = [text];
    for (const m of text.matchAll(/<mj-include\s+path="([^"]+)"/g)) {
        parts.push(await readFile(path.join(path.dirname(file), m[1]), 'utf8'));
    }
    return parts.join('\n');
}

const files = (await readdir(srcDir)).filter(f => f.endsWith('.mjml')).sort();
let failed = false;

for (const file of files) {
    const name = file.replace(/\.mjml$/, '');
    const srcPath = path.join(srcDir, file);
    let html;
    try {
        ({ html } = await mjml2html(await readFile(srcPath, 'utf8'), {
            filePath: srcPath,
            includePath: srcDir,
            ignoreIncludes: false,
            // no web-font links: a mail would fetch them from Google on every open
            fonts: {},
            keepComments: false,
            // strict throws on any validation error instead of returning it
            validationLevel: 'strict',
        }));
    } catch (e) {
        console.error(`${file}: ${e.errors?.map(x => x.formattedMessage).join('; ') ?? e.message}`);
        failed = true;
        continue;
    }

    const lost = [...new Set((await withIncludes(srcPath)).match(askamaToken) ?? [])].filter(
        t => !html.includes(t),
    );
    if (lost.length) {
        console.error(`${file}: askama tokens changed by MJML: ${lost.join(' ')}`);
        failed = true;
        continue;
    }
    if (html.includes('{#')) {
        console.error(`${file}: the output contains "{#", which askama reads as a comment`);
        failed = true;
        continue;
    }

    const out = `${html}\n{# Generated from funcd/email/src/${file} by funcd/email/build.mjs: edit the source, not this file. #}\n`;
    const outPath = path.join(outDir, `${name}.html`);
    if (check) {
        const current = await readFile(outPath, 'utf8').catch(() => '');
        if (current !== out) {
            console.error(`stale: templates/email/${name}.html (run npm run build in funcd/email)`);
            failed = true;
        }
    } else {
        await writeFile(outPath, out);
        console.log(`templates/email/${name}.html`);
    }
}

if (failed) {
    process.exit(1);
}
