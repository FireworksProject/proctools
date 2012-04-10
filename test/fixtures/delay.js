setTimeout(function () {
    process.stdout.write('first stdout');
}, 300);

setTimeout(function () {
    process.stdout.write(' second stdout');
}, 700);

setTimeout(function () {
    process.exit();
}, 1000);
