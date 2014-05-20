var gulp = require('gulp')
var concat = require('gulp-concat')
var coffee = require('gulp-coffee')
var uglify = require('gulp-uglify')
var karma = require('gulp-karma')

gulp.task("default", ['spec'], function(){
  gulp.watch('./src/**/*', ["build"])
})

var SRC_FILES = ["./src/subset.coffee", "./src/paginator.coffee", "./src/paginator_view.coffee"]

gulp.task("build", function(){
  gulp.src(SRC_FILES)
    .pipe(concat("batman.paginator.coffee"))
    .pipe(gulp.dest("./dist/"))
    .pipe(coffee())
    .pipe(gulp.dest("./dist/"))
    .pipe(uglify())
    .pipe(concat("batman.paginator.min.js"))
    .pipe(gulp.dest("./dist/"))
})

gulp.task("spec", function(){
  gulp.src(["batman.paginator.js"])
    .pipe(karma({
        configFile: './spec/support/config.coffee',
        action: 'watch'
      }))
})