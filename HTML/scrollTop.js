

function printScrollTop() {
    var elmnt = document.getElementById("myDIV");
    var y = elmnt.scrollTop;
    window.console.log("myDIV scrollTop=" + y);
    window.console.log("documentElement scrollTop=" + document.documentElement.scrollTop);

    setTimeout(printScrollTop, 300);
};

setTimeout(printScrollTop, 300);



function TestScrollTop() {

//debugger;

//    document.documentElement.scrollTop = 2000;

    var elmnt = document.getElementById("myDIV");
    elmnt.scrollTop = 5000;
}

