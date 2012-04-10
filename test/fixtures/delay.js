setTimeout(function () {
    process.stdout.write('first stdout');
}, 300);

setTimeout(function () {
    process.stdout.write(' second stdout');
}, 1400);

setTimeout(function () {
    process.exit();
}, 1600);
