setTimeout(function () {
    process.stdout.write('second stdout');
}, 300);

setTimeout(function () {
    process.stdout.write('third stdout');
}, 1400);

setTimeout(function () {
    process.exit();
}, 1600);

process.stdout.write('first stdout');
