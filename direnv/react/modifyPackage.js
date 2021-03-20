const PATH = `${process.cwd()}/package.json`;

const fs = require("fs");
const packageJson = require(PATH);

// パッケージが消えてしまう現象を防ぐため、パッケージを新たに追加するとき、一旦リンクを解除する。
packageJson.scripts.preinstall =
  "command -v link-module-alias && link-module-alias clean || true";
packageJson.scripts.postinstall = "link-module-alias";
// storybook から babel-loader を使用しやすいように、link-module-alias でシンボリックリンクを作成している
// この babel-loader は react-scripts が使用していて、
packageJson._moduleAliases = {
  "babel-loader": "node_modules/react-scripts/node_modules/babel-loader",
};

// インデント 2 で json を出力
fs.writeFileSync(PATH, JSON.stringify(packageJson, null, 2));