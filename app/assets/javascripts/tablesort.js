(function(){
  var tablesorterConfig = {
    cssHeader: 'header',
    cssAsc: 'headerSortUp',
    cssDesc: 'headerSortDown'
  };

  document.addEventListener("contributor-comparison-loaded", function(){
    $("#comparison").tablesorter(tablesorterConfig);

    // Single-pass scan: collect column classes that have at least one non-empty, non-zero cell.
    var colsWithData = new Set();
    document.querySelectorAll('#comparison tbody td').forEach(function(cell) {
      var colClass = cell.classList[0];
      if (colClass && !colsWithData.has(colClass) && cell.textContent.trim() !== '' && cell.textContent.trim() !== '0') {
        colsWithData.add(colClass);
      }
    });

    // Hide columns where every cell is empty or zero.
    document.querySelectorAll('form.comparison input[name="column"]').forEach(function(checkbox) {
      if (!colsWithData.has(checkbox.value)) {
        checkbox.checked = false;
        toggle_column(checkbox);
      }
    });
  });

  document.addEventListener("turbo:load", function(){
    $("#users").tablesorter(tablesorterConfig);
  });
})();
