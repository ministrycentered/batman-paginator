module.exports = (config) ->
  config.set
    basePath: "../"
    frameworks: ['jasmine']
    files: [
      '../dist/batman.paginator.coffee'
      'lib/batman.js'
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
