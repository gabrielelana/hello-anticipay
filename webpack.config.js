const path = require("path");
const autoprefixer = require("autoprefixer");
const ExtractTextPlugin = require("extract-text-webpack-plugin");
const CopyWebpackPlugin = require("copy-webpack-plugin");

const devBuild = process.env.NODE_ENV !== "production";
const nodeEnv = devBuild ? "development" : "production";
const webpack = require("webpack");

module.exports = {
  entry: [
    // 'es6-promise',
    // 'babel-polyfill',
    path.join(__dirname, "ui/js/app.jsx"),
    path.join(__dirname, "ui/css/app.scss")
  ],
  output: {
    path: path.join(__dirname, "/priv/static"),
    filename: "js/app.js"
  },
  module: {
    rules: [
      {
        test: /\.(js|jsx)$/,
        exclude: ["/node_modules/"],
        include: path.join(__dirname, "ui/js"),
        use: [
          {
            loader: "babel-loader",
            options: {
              presets: ["env", "react"]
            }
          }
        ]
      },
      {
        test: /\.css$/,
        use: ExtractTextPlugin.extract({
          fallback: "style-loader",
          use: [
            "css-loader?modules&importLoaders=1&localIdentName=[name]__[local]___[hash:base64:5]",
            {
              loader: "postcss-loader",
              options: {
                plugins: [
                  autoprefixer({
                    browsers: ["last 3 version", "ie >= 10"]
                  })
                ]
              }
            }
          ]
        })
      },
      {
        test: /\.(sass|scss)$/,
        use: ExtractTextPlugin.extract({
          fallback: "style-loader",
          use: [
            "css-loader?modules&importLoaders=1&localIdentName=[name]__[local]___[hash:base64:5]",
            {
              loader: "postcss-loader",
              options: {
                plugins: [
                  autoprefixer({
                    browsers: ["last 3 version", "ie >= 10"]
                  })
                ]
              }
            },
            "sass-loader"
          ]
        })
      },
      {
        test: /\.woff(2)?(\?v=[0-9]\.[0-9]\.[0-9])?$/,
        loader: "url-loader?limit=10000&mimetype=application/font-woff"
      },
      {
        test: /\.(ttf|eot|svg)(\?v=[0-9]\.[0-9]\.[0-9])?$/,
        loader: "file-loader"
      },
      {
        test: /\.(jpg|png)(\?v=[0-9]\.[0-9]\.[0-9])?$/,
        loader: "url-loader"
      }
    ]
  },
  resolve: {
    extensions: [
      ".webpack-loader.js",
      ".web-loader.js",
      ".loader.js",
      ".js",
      ".jsx",
      ".scss",
      ".css"
    ],
    modules: ["node_modules", "ui/js"],
    // alias: {
      // phoenix: path.join(__dirname, "/deps/phoenix/priv/static/phoenix.js")
    // }
  },
  plugins: [
    new ExtractTextPlugin({
      filename: "css/app.css",
      disable: false,
      allChunks: true
    }),
    // new CopyWebpackPlugin([
    //   { from: "./web/static/assets" },
    //   { from: "./web/static/vendor/css", to: "css/vendor" },
    //   { from: "./web/static/vendor/es6-promise.map", to: "js" },
    //   { from: "./web/static/vendor/js", to: "js/vendor" }
    // ]),
    new webpack.DefinePlugin({
      "process.env": {
        NODE_ENV: JSON.stringify(nodeEnv)
      }
    })
  ]
};
