(function(){
  // This is the turbolinks equivalent to a page load.
  document.addEventListener("contributor-comparison-loaded", function(){

    $(document).ready(function() {
      
      $("#comparison").tablesorter({
        cssHeader: 'header',
        cssAsc: 'headerSortUp',
        cssDesc: 'headerSortDown'
      });
    });
  });
})();
