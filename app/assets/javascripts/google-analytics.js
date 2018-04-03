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

      // Authorization
      var accessToken = document.getElementById("access-token").dataset.accessToken;
      var profileId = document.getElementById("profile-id").dataset.profileId;

      gapi.analytics.auth.authorize({
        'serverAuth': {
          'access_token': accessToken
        }
      });


      // Step 5: Create the timeline chart.

      var timeline = new gapi.analytics.googleCharts.DataChart({
        reportType: 'ga',
        query: {
          'ids': profileId,
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
        timeline.execute();
      }
    });
  });
})();
