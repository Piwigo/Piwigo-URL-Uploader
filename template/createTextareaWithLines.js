function createTextAreaWithLines(id) {
  var el = document.createElement('TEXTAREA');
  var ta = document.getElementById(id);

  el.style.resize = 'none';
  ta.style.resize = 'none';
  ta.wrap = 'off';

  var string = '';
  for (var no=1;no<1000;no++) {
    if (string.length>0) string += '\n';
    string += no;
  }
  
  el.className      = 'textAreaWithLines';
  el.style.height   = (ta.offsetHeight-3) + "px";
  el.style.display  = "block";
  el.style.width    = "25px";
  el.style.position = "absolute";
  el.style.overflow = 'hidden';
  el.style.textAlign = 'right';
  el.style.paddingRight = '0.2em';
  el.innerHTML      = string;  //Firefox renders \n linebreak
  el.innerText      = string; //IE6 renders \n line break
  el.style.zIndex   = 0;
  el.style.border   = "none";
  el.style.background = "none";
  
  ta.style.marginLeft = "20px"
  ta.style.zIndex   = 1;
  ta.style.position = "relative";
  ta.parentNode.insertBefore(el, ta.nextSibling);

  setLine();
  ta.onkeydown    = function() { setLine(); }
  ta.onmousedown  = function() { setLine(); }
  ta.onscroll     = function() { setLine(); }
  ta.onblur       = function() { setLine(); }
  ta.onfocus      = function() { setLine(); }
  ta.onmouseover  = function() { setLine(); }
  ta.onmouseup    = function() { setLine(); }

  function setLine() {
    el.scrollTop   = ta.scrollTop;
    el.style.top   = (ta.offsetTop) + "px";
    el.style.left  = (ta.offsetLeft - 27) + "px";
  }
}