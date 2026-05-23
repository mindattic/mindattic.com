#!/usr/bin/env node
/*
 * render-readme.js -- read Markdown from stdin, write HTML to stdout.
 *
 * Mirrors the per-repo build-html.js renderer (GFM via marked,
 * token-classed syntax highlighting via highlight.js, per-heading anchor
 * links at h2-h4) so the centralized mindattic.com landing pages keep the
 * same look as the legacy per-repo pages they replace.
 *
 * Usage:
 *   gh api repos/owner/repo/readme --jq .content | base64 -d | node render-readme.js
 *
 * Stdin is expected to be UTF-8 Markdown. Stdout is UTF-8 HTML.
 */

'use strict';

const { marked } = require('marked');
const hljs = require('highlight.js');

function slugify(t) {
    return String(t)
        .toLowerCase()
        .replace(/[^a-z0-9\s-]/g, '')
        .trim()
        .replace(/\s+/g, '-')
        .replace(/-+/g, '-');
}

marked.setOptions({
    gfm: true,
    breaks: false,
    headerIds: true,
    mangle: false,
    highlight(code, lang) {
        try {
            if (lang && hljs.getLanguage(lang)) {
                return hljs.highlight(code, { language: lang }).value;
            }
        } catch (_) {}
        return hljs.highlightAuto(code).value;
    },
});

const renderer = new marked.Renderer();
renderer.heading = function (text, level, raw) {
    const id = slugify(raw);
    const anchor = level >= 2 && level <= 4
        ? ` <a class="heading-anchor" href="#${id}" aria-label="link to this section">#</a>`
        : '';
    return `<h${level} id="${id}">${text}${anchor}</h${level}>\n`;
};

let buf = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', d => { buf += d; });
process.stdin.on('end', () => {
    try {
        const html = marked.parse(buf, { renderer });
        process.stdout.write(html);
    } catch (e) {
        process.stderr.write('render-readme.js: ' + e.message + '\n');
        process.exit(1);
    }
});
