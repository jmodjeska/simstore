$(document).ready(function(){

  update_db_name();
  var responseCode = "";

  function getCookie(cname) {
    var name = cname + "=";
    var ca = document.cookie.split(';');
    for(var i=0; i<ca.length; i++) {
      var c = ca[i];
      while (c.charAt(0)==' ') c = c.substring(1);
      if (c.indexOf(name) == 0) return c.substring(name.length,c.length);
    }
  return "";
  }

  function update_db_name() {
    db = getCookie("db") || "None";
    // Override db in cookie with db from URL param. Could happen.
    if( $("#user-specified-db").text().trim() != '' ) {
      db = $("#user-specified-db").text().trim();
      document.cookie="db=" + db;
    }
    $("#db-display-name").text(db);
    if(db == "None") {
      $("#kill-db").hide();
    }
    else {
      $("#kill-db").show();
    }
  }

  $(document).on('click', '#kill-db', function(){
    document.cookie="db=;";
    update_db_name();
    $("#manageStoreContainer").fadeOut('fast', function(){
      $("#defaultStoreSetup").fadeIn('fast');
    });
  });

  $(document).on('click', '#runSim', function(){
    var holder = $("#runSim").text();
    var type = $("#simType").text();
    $("#runSim").addClass('disabled');
    $("#runSim").html(holder + ' <i class="fa fa-cog fa-spin"></i>');
    run_sim(holder, type);
  });

  $(document).on('click', '#defaultStoreSetup', function(){
    $("#defaultStoreSetup").addClass('disabled');
    $("#defaultStoreSetup").html('Build <i class="fa fa-cog fa-spin"></i>');
    init_store();
  });

  function init_store() {
    $("#setup-hidden").load("/modal_new_store",
    function(responseTxt, statusTxt, xhr) {
      if(statusTxt == "success") {
        var dbname = $("#setup-hidden").text().trim();
        console.log("Got new db: " + dbname);
        document.cookie="db=" + dbname;
        update_db_name();
        setup_loop();
      }
      if(statusTxt == "error") {
        $("#errorText").text(xhr.status + ": " + xhr.statusText);
        $("#errorMessage").show();
      }
    });
  }

  function setup_loop() {
    jQuery.ajaxSetup({async:false});
    $("#setup-hidden").load("/modal_store_do_next?db=" + db,
      // Naive endpoint calls, because SimStore knows what to do next
      function(responseTxt, statusTxt, xhr) {
        if(statusTxt == "success") {
          responseCode = $("#setup-hidden").text().trim();
          console.log("Received response: " + responseCode)
          update_db_name();
        }
        if(statusTxt == "error") {
          $("#errorText").text(xhr.status + ": " + xhr.statusText);
          $("#errorMessage").show();
        }
      });
    if ( responseCode == "true" ) {
      // SimStore returns "true" until setup is complete
      setup_loop();
    }
    else {
      // Store's ready
      $("#defaultStoreSetup").fadeOut('fast', function(){
        $("#manageStore").attr("href", "manage_store?db=" + db)
        $("#manageStoreContainer").fadeIn('fast');
      });
      $("#defaultStoreSetup").removeClass('disabled');
      $("#defaultStoreSetup").html('Build');
    }
    jQuery.ajaxSetup({async:true});
  }

  function run_sim(holder, sim_type) {
    $("#setup-hidden").load("/modal_" + sim_type + "?db=" + db,
    function(responseTxt, statusTxt, xhr) {
      if(statusTxt == "success") {
        $("#runSim").fadeOut('fast', function(){
          $("#manageStore").attr("href", "manage_store?db=" + db)
          $("#manageStoreContainer").fadeIn('fast');
        });
        $("#runSim").removeClass('disabled');
        $("#runSim").text(holder);
      }
      else {
        $("#errorText").text(xhr.status + ": " + xhr.statusText);
        $("#errorMessageContainer").css("padding-left", "300");
        $("#errorMessage").show();
      }
    });
  }

});
