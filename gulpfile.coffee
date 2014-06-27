gulp = require 'gulp'
gutil = require 'gulp-util'
jade = require 'gulp-jade'
concat = require 'gulp-concat'
clean = require 'gulp-clean'
stylus = require 'gulp-stylus'
browserify = require 'browserify'
watchify = require 'watchify'
uglify = require 'gulp-uglify'
minifyCss = require 'gulp-minify-css'
source = require 'vinyl-source-stream'
preprocess = require 'gulp-preprocess'
nib = require 'nib'
browserSync = require 'browser-sync'
modRewrite = require 'connect-modrewrite'
pkg = require './package.json'

gulp.task 'server', ->
  baseDir = process.env.NODE_ENV ? 'compiled'

  browserSync.init null,
    server:
      baseDir: "./#{baseDir}"
      middleware: [
        modRewrite([
          '^[^\\.]*$ /index.html [L]'
        ])
      ]

context = VERSION: pkg.version

compiledDir = './compiled'
distDir = './dist'

gulp.task 'jade', ->
  dir = if context.COMPILE then compiledDir else distDir
  gulp.src('./src/index.jade')
    .pipe(jade())
    .pipe(preprocess(context: context))
    .pipe(gulp.dest(dir))
#    .pipe(connect.reload())
    .pipe(browserSync.reload(stream: true))


gulp.task 'copy-css', ->
  gulp.src('./node_modules/codemirror/lib/codemirror.css')
  .pipe(gulp.dest("#{compiledDir}/css"))

gulp.task 'stylus', ->
  gulp.src('./src/stylus/**/*')
    # .pipe(plumber())
    .pipe(stylus(
      use: [nib()]
    ))
    .pipe(concat("main-#{pkg.version}.css"))
    .pipe(gulp.dest("#{compiledDir}/css"))
#    .pipe(connect.reload())
    .pipe(browserSync.reload(stream: true))

gulp.task 'uglify', ->
  gulp.src("#{compiledDir}/js/*")
    .pipe(concat("main-#{pkg.version}.js", newLine: '\r\n;'))
    .pipe(uglify())
    .pipe(gulp.dest(distDir+'/js/'))

gulp.task 'minify-css', ->
  gulp.src("#{compiledDir}/css/main-#{pkg.version}.css")
    .pipe(minifyCss())
    .pipe(gulp.dest(distDir+'/css'))

gulp.task 'clean-compiled', -> gulp.src(compiledDir+'/*').pipe(clean())
gulp.task 'clean-dist', -> gulp.src(distDir+'/*').pipe(clean())

gulp.task 'copy-static-compiled', -> gulp.src('./static/**/*').pipe(gulp.dest(compiledDir))
gulp.task 'copy-static-dist', -> gulp.src('./static/**/*').pipe(gulp.dest(distDir))

gulp.task 'compile', ['clean-compiled'], ->
  context.COMPILE = true
  gulp.start 'copy-css'
  gulp.start 'copy-static-compiled'
  gulp.start 'browserify'
  gulp.start 'jade'
  gulp.start 'stylus'

gulp.task 'build', ['clean-dist'], ->
  gulp.start 'jade'
  gulp.start 'copy-static-dist'
  gulp.start 'uglify'
  gulp.start 'minify-css'

gulp.task 'watch', ->
  context.COMPILE = true
  gulp.watch ['./src/index.jade'], ['jade']
  gulp.watch ['./src/stylus/**/*'], ['stylus']

createBundle = (watch=false) ->
  args =
    entries: './src/coffee/index.coffee'
    extensions: ['.coffee', '.jade']

  bundler = if watch then watchify(args) else browserify(args)

  bundler.transform('coffeeify')
  bundler.transform('jadeify')
  bundler.transform('envify')

  bundler.exclude 'jquery'
  bundler.exclude 'underscore'
  bundler.exclude 'backbone'

  rebundle = ->
    gutil.log('Watchify rebundling') if watch
    bundler.bundle()
      .pipe(source("src-#{pkg.version}.js"))
      .pipe(gulp.dest("#{compiledDir}/js"))
#      .pipe(connect.reload())
      .pipe(browserSync.reload({stream:true, once: true}))

  bundler.on('update', rebundle)

  rebundle()

gulp.task 'browserify', -> createBundle false
gulp.task 'watchify', -> createBundle true

gulp.task 'default', ['stylus', 'server', 'watch', 'watchify']