(function(){
  // This is the turbo equivalent to a page load.
  document.addEventListener("turbo:load", function(){

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
      
      var segment = document.getElementById("segment") ? 
        document.getElementById("segment").dataset.segment : "";

      // Authorization

      gapi.analytics.auth.authorize({
        'serverAuth': {
          'access_token': accessToken
        }
      });

      var usMapContainer = 'us-map';
      var worldMapContainer = 'world-map';
      var userGraphContainer = 'user-timeline';
      var sessionGraphContainer = 'session-timeline';
      var itemViewGraphContainer = 'item-view-timeline';
      var clickThroughGraphContainer = 'click-through-timeline';
      var apiItemViewGraphContainer = 'api-item-view-timeline';
      var apiUserGraphContainer = 'api-user-timeline';

      // Create map

      var filters = function(){
        var filters = ["ga:eventCategory=@" + hub, "ga:eventCategory!~Browse.*"];

        if (contributor !== "") {
          filters = filters.concat("ga:eventAction==" + contributor.replace(",", "\\,"));
        }

        return filters.join(';');
      };

      var itemViewFilters = function() {
        return filters().concat(";ga:eventCategory!~Click.*");
      };

      var clickThroughFilters = function() {
        return filters().concat(";ga:eventCategory!~View.*");
      };

      var usMap = new gapi.analytics.googleCharts.DataChart({
        reportType: 'ga',
        query: {
          'ids': profileId,
          'dimensions': 'ga:region',
          'metrics': 'ga:users',
          'filters': filters(),
          'start-date': startDate,
          'end-date': endDate
        },
        chart: {
          type: 'GEO',
          container: usMapContainer,
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
          'filters': filters(),
          'start-date': startDate,
          'end-date': endDate
        },
        chart: {
          type: 'GEO',
          container: worldMapContainer
        }
      });

      // Create line graph

      var userGraph = new gapi.analytics.googleCharts.DataChart({
        reportType: 'ga',
        query: {
          'ids': profileId,
          'dimensions': 'ga:yearMonth',
          'metrics': 'ga:users',
          'filters': filters(),
          'start-date': startDate,
          'end-date': endDate
        },
        chart: {
          type: 'LINE',
          container: userGraphContainer
        }
      });

      var sessionGraph = new gapi.analytics.googleCharts.DataChart({
        reportType: 'ga',
        query: {
          'ids': profileId,
          'dimensions': 'ga:yearMonth',
          'metrics': 'ga:sessions',
          'filters': filters(),
          'start-date': startDate,
          'end-date': endDate
        },
        chart: {
          type: 'LINE',
          container: sessionGraphContainer
        }
      });

      var itemViewGraph = new gapi.analytics.googleCharts.DataChart({
        reportType: 'ga',
        query: {
          'ids': profileId,
          'dimensions': 'ga:yearMonth',
          'metrics': 'ga:totalEvents',
          'filters': itemViewFilters(),
          'start-date': startDate,
          'end-date': endDate
        },
        chart: {
          type: 'LINE',
          container: itemViewGraphContainer
        }
      });

      var clickThroughGraph = new gapi.analytics.googleCharts.DataChart({
        reportType: 'ga',
        query: {
          'ids': profileId,
          'dimensions': 'ga:yearMonth',
          'metrics': 'ga:totalEvents',
          'filters': clickThroughFilters(),
          'start-date': startDate,
          'end-date': endDate
        },
        chart: {
          type: 'LINE',
          container: clickThroughGraphContainer
        }
      });

      var apiUserGraph = new gapi.analytics.googleCharts.DataChart({
        reportType: 'ga',
        query: {
          'ids': profileId,
          'dimensions': 'ga:yearMonth',
          'metrics': 'ga:users',
          'filters': filters(),
          'start-date': startDate,
          'end-date': endDate,
          'segment': segment
        },
        chart: {
          type: 'LINE',
          container: apiUserGraphContainer
        }
      });

      var apiItemViewGraph = new gapi.analytics.googleCharts.DataChart({
        reportType: 'ga',
        query: {
          'ids': profileId,
          'dimensions': 'ga:yearMonth',
          'metrics': 'ga:totalEvents',
          'filters': itemViewFilters(),
          'start-date': startDate,
          'end-date': endDate,
          'segment': segment
        },
        chart: {
          type: 'LINE',
          container: apiItemViewGraphContainer
        }
      });
      
      // Render visualiztions if authorization is successful.
      // If the request fails, visualizations will not render.

      if (gapi.analytics.auth.isAuthorized()) {
        if (document.getElementById(usMapContainer)) { usMap.execute() }
        if (document.getElementById(worldMapContainer)) { worldMap.execute() }
        if (document.getElementById(userGraphContainer)) { userGraph.execute() }
        if (document.getElementById(sessionGraphContainer)) { sessionGraph.execute() }
        if (document.getElementById(itemViewGraphContainer)) { itemViewGraph.execute() }
        if (document.getElementById(clickThroughGraphContainer)) { clickThroughGraph.execute() }
        if (document.getElementById(apiItemViewGraphContainer)) { apiItemViewGraph.execute() }
        if (document.getElementById(apiUserGraphContainer)) { apiUserGraph.execute() }
      }
    });
  });
})();
