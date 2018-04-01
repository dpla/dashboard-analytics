(function(){
  // This is the turbolinks equivalent to a page load.
  document.addEventListener("turbolinks:load", function(){

    (function(w,d,s,g,js,fjs){
      g=w.gapi||(w.gapi={});g.analytics={q:[],ready:function(cb){this.q.push(cb)}};
      js=d.createElement(s);fjs=d.getElementsByTagName(s)[0];
      js.src='https://apis.google.com/js/platform.js';
      fjs.parentNode.insertBefore(js,fjs);js.onload=function(){g.load('analytics')};
    }(window,document,'script')); 

    gapi.analytics.ready(function() {

      // alert('checkpoint');

      // Step 3: Authorize the user.

      var access_token = document.getElementById("access-token").dataset.accessToken;

      // alert(access_token);

      gapi.analytics.auth.authorize({
        'serverAuth': {
          'access_token': access_token
        }
      });

      // Step 4: Create the view selector.

      var viewSelector = new gapi.analytics.ViewSelector({
        container: 'view-selector'
      });

      // Step 5: Create the timeline chart.

      var timeline = new gapi.analytics.googleCharts.DataChart({
        reportType: 'ga',
        query: {
          'dimensions': 'ga:date',
          'metrics': 'ga:sessions',
          'start-date': '30daysAgo',
          'end-date': 'yesterday',
        },
        chart: {
          type: 'LINE',
          container: 'timeline'
        }
      });
      
      // Step 6: Hook up the components to work together.

      if (gapi.analytics.auth.isAuthorized()) {
        viewSelector.execute();
      }

      viewSelector.on('change', function(ids) {
        var newIds = {
          query: {
            ids: ids
          }
        }
        timeline.set(newIds).execute();
      });
    });
  });
})();
