const PATH = `${process.cwd()}/tsconfig.json`;

const fs = require("fs");
const packageJson = require(PATH);

// 本体のコンパイルに stories は関係ないため、除外する
packageJson.exclude = ["**/stories"];

// インデント 2 で json を出力
fs.writeFileSync(PATH, JSON.stringify(packageJson, null, 2));