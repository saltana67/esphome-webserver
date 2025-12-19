import { defineConfig } from "vite";
import { viteSingleFile } from "vite-plugin-singlefile";
import { createHtmlPlugin } from "vite-plugin-html";
import gzipPlugin from "rollup-plugin-gzip";

export default defineConfig({
  clearScreen: false,
  plugins: [
    viteSingleFile(),
    createHtmlPlugin({
      minify: {
        collapseWhitespace: true,
        removeComments: true,
        removeAttributeQuotes: true,
        removeRedundantAttributes: true,
        removeScriptTypeAttributes: true,
        removeStyleLinkTypeAttributes: true,
        removeEmptyAttributes: true,
        collapseBooleanAttributes: true,
        sortAttributes: true,
        sortClassName: true,
        minifyCSS: true,
        minifyJS: true,
      },
    }),
    {
      ...gzipPlugin({ filter: /\.(html)$/ }),
      enforce: "post",
      apply: "build",
    },
  ],
  build: {
    minify: "terser",
    terserOptions: {
      compress: { passes: 2, unsafe: true, drop_console: true },
      mangle: true,
    },
    outDir: "./_static/captive_portal",
    assetsInlineLimit: 100000000,
    modulePreload: false,
  },
  server: {
    open: "/",
  },
});
