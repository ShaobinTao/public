

function printScrollTop() {
    var elmnt = document.getElementById("myDIV");
    var y = elmnt.scrollTop;
    window.console.log("scrollTop=" + y);
//    window.console.log("scrollTop=" + document.documentElement.scrollTop);
    setTimeout(printScrollTop, 300);
};


setTimeout(printScrollTop, 300);





function TestScrollTop() {

//debugger;

    document.documentElement.scrollTop = 8800;

    console.log("client height=" + document.documentElement.clientHeight);
    console.log("scroll height=" + document.documentElement.scrollHeight);
    console.log("");
}

