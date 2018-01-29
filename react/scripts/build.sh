#transpile the source js. take all files from js/source, transpile using the react and es2015 capabilities, copy them to js/build

./node_modules/.bin/babel --presets react,es2015 js/source -d js/build


# package JS, start with js/build/app.js, follow all deps, and write the result to bundle.js
./node_modules/.bin/browserify js/build/app.js -o bundle.js


# CSS package
cat css/*/* css/*.css | sed 's/..\/..\/images/images/g' > bundle.css


