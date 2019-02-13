(function(){
  // Event listener executes when async partial load is completed.
  document.addEventListener("contributor-comparison-loaded", function(){

    $(document).ready(function() {
      
      $("#comparison").tablesorter({
        cssHeader: 'header',
        cssAsc: 'headerSortUp',
        cssDesc: 'headerSortDown'
      });
    });
  });

  document.addEventListener("turbolinks:load", function(){
    console.log("hello");
    $("#users").tablesorter({
      cssHeader: 'header',
      cssAsc: 'headerSortUp',
      cssDesc: 'headerSortDown'
    });
  });
})();
