module.exports = (config) ->
  config.set
    basePath: "../"
    plugins: [
      'karma-coffee-preprocessor',
      'karma-jasmine',
      'karma-chrome-launcher',
    ]
    preprocessors: {
      '**/*.coffee': ['coffee']
    }
    frameworks: ['jasmine']
    files: [
      'lib/batman.js'
      '../dist/batman.paginator.js'
      '../spec/support/batman_request_mocks.coffee'
      '**/*_spec.coffee'
    ]
    exclude: []
    reporters: ['dots']
    port: 9876
    colors: true
    logLevel: config.LOG_INFO
    autoWatch: true
    browsers: [
        'Chrome'
    ]
    captureTimeout: 60000
    singleRun: false
