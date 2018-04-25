(function(){
  // This is the turbolinks equivalent to a page load.
  document.addEventListener("turbolinks:load", function(){

    // Load google analytics api

    (function(w,d,s,g,js,fjs){
      g=w.gapi||(w.gapi={});g.analytics={q:[],ready:function(cb){this.q.push(cb)}};
      js=d.createElement(s);fjs=d.getElementsByTagName(s)[0];
      js.src='https://apis.google.com/js/platform.js';
      fjs.parentNode.insertBefore(js,fjs);js.onload=function(){g.load('analytics')};
    }(window,document,'script')); 

    gapi.analytics.ready(function() {

      // Read data from HTML

      var accessToken = document.getElementById("access-token").dataset.accessToken;
      var profileId = document.getElementById("profile-id").dataset.profileId;
      var hub = document.getElementById("hub").dataset.hub;
      var contributor = document.getElementById("contributor").dataset.contributor;
      var startDate = document.getElementById("start-date").dataset.startDate;
      var endDate = document.getElementById("end-date").dataset.endDate;

      // Authorization

      gapi.analytics.auth.authorize({
        'serverAuth': {
          'access_token': accessToken
        }
      });

      // Create map

      var mapFilters = function(){
        var filters = [`ga:eventCategory=@${hub}`, `ga:eventCategory!@Browse`];

        if (contributor !== "") {
          filters = filters.concat(`ga:eventAction==${contributor}`);
        }

        return filters.join(';');
      };

      var usMap = new gapi.analytics.googleCharts.DataChart({
        reportType: 'ga',
        query: {
          'ids': profileId,
          'dimensions': 'ga:region',
          'metrics': 'ga:users',
          'filters': mapFilters(),
          'start-date': startDate,
          'end-date': endDate,
        },
        chart: {
          type: 'GEO',
          container: 'us-map',
          options: {
            region: 'US',
            resolution: 'provinces'
          }
        }
      });

      var worldMap = new gapi.analytics.googleCharts.DataChart({
        reportType: 'ga',
        query: {
          'ids': profileId,
          'dimensions': 'ga:country',
          'metrics': 'ga:users',
          'filters': mapFilters(),
          'start-date': startDate,
          'end-date': endDate,
        },
        chart: {
          type: 'GEO',
          container: 'world-map'
        }
      });
      
      // Render visualiztions if authorization is successful.
      // If the request fails, visualizations will not render.

      if (gapi.analytics.auth.isAuthorized()) {
        usMap.execute();
        worldMap.execute();
      }
    });
  });
})();
