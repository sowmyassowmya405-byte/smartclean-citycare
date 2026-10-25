/* =====================================================
   SmartClean - CityCare  (simple version)
   Data is saved in the browser using localStorage.
   ===================================================== */


/* ---------- 1. DATA (loading saved data) ---------- */

// Get saved users. If nothing is saved, start with one admin account.
var users = JSON.parse(localStorage.getItem("users")) || [
  { name: "Admin", email: "admin@gmail.com", password: "admin123", role: "admin" }
];

// Get saved complaints. If nothing is saved, start with an empty list.
var complaints = JSON.parse(localStorage.getItem("complaints")) || [];

// Who is logged in now? (null means nobody)
var currentUser = JSON.parse(localStorage.getItem("currentUser")) || null;


/* ---------- 2. SAVE DATA ---------- */

// localStorage only stores text, so we convert lists to text with JSON.stringify
function saveData() {
  localStorage.setItem("users", JSON.stringify(users));
  localStorage.setItem("complaints", JSON.stringify(complaints));
  localStorage.setItem("currentUser", JSON.stringify(currentUser));
}


/* ---------- 3. SHOW ONE PAGE ---------- */

// Hide all pages, then show only the page we want
function showPage(pageId) {
  var pages = document.getElementsByClassName("page");
  for (var i = 0; i < pages.length; i++) {
    pages[i].style.display = "none";
  }
  document.getElementById(pageId).style.display = "block";
}


/* ---------- 4. MENU BUTTONS (show / hide by login) ---------- */

function updateMenu() {
  var loggedIn = currentUser !== null;
  var isAdmin  = loggedIn && currentUser.role === "admin";

  // Show a button with "inline-block", hide it with "none"
  document.getElementById("btnLogin").style.display    = loggedIn ? "none" : "inline-block";
  document.getElementById("btnRegister").style.display = loggedIn ? "none" : "inline-block";
  document.getElementById("btnLogout").style.display   = loggedIn ? "inline-block" : "none";

  // Citizen buttons
  document.getElementById("btnReport").style.display = (loggedIn && !isAdmin) ? "inline-block" : "none";
  document.getElementById("btnMine").style.display   = (loggedIn && !isAdmin) ? "inline-block" : "none";

  // Admin button
  document.getElementById("btnAdmin").style.display  = isAdmin ? "inline-block" : "none";
}


/* ---------- 5. REGISTER ---------- */

function register() {
  var name     = document.getElementById("regName").value;
  var email    = document.getElementById("regEmail").value;
  var password = document.getElementById("regPassword").value;

  // Check that nothing is empty
  if (name == "" || email == "" || password == "") {
    alert("Please fill all the fields");
    return;
  }

  // Check if this email is already registered
  for (var i = 0; i < users.length; i++) {
    if (users[i].email == email) {
      alert("This email is already registered");
      return;
    }
  }

  // Add the new user to the list
  users.push({ name: name, email: email, password: password, role: "citizen" });
  saveData();

  alert("Registered successfully! Please login.");
  showPage("login");
}


/* ---------- 6. LOGIN / LOGOUT ---------- */

function login() {
  var email    = document.getElementById("loginEmail").value;
  var password = document.getElementById("loginPassword").value;

  // Search the users list for a matching email and password
  for (var i = 0; i < users.length; i++) {
    if (users[i].email == email && users[i].password == password) {
      currentUser = users[i];
      saveData();
      updateMenu();
      alert("Welcome " + currentUser.name);

      // Admin goes to admin panel, citizen goes to home
      if (currentUser.role == "admin") {
        showAllComplaints();
      } else {
        showPage("home");
      }
      return;
    }
  }

  alert("Wrong email or password");
}

function logout() {
  currentUser = null;
  saveData();
  updateMenu();
  showPage("home");
}


/* ---------- 7. SUBMIT A COMPLAINT ---------- */

function submitComplaint() {
  var category    = document.getElementById("category").value;
  var description = document.getElementById("description").value;
  var location    = document.getElementById("location").value;

  if (description == "" || location == "") {
    alert("Please write the description and location");
    return;
  }

  // Make a unique ID: SC-1001, SC-1002, SC-1003 ...
  var id = "SC-" + (1001 + complaints.length);

  // One complaint is one object
  var complaint = {
    id: id,
    email: currentUser.email,       // who reported it
    category: category,
    description: description,
    location: location,
    status: "Pending",              // every new complaint starts as Pending
    date: new Date().toLocaleDateString()
  };

  complaints.push(complaint);
  saveData();

  alert("Complaint submitted! Your complaint ID is " + id);

  // Clear the form
  document.getElementById("description").value = "";
  document.getElementById("location").value = "";

  showMyComplaints();
}


/* ---------- 8. SHOW COMPLAINTS ---------- */

// Small helper: stops users from typing HTML code into the page (security)
function safe(text) {
  return String(text).replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

// Make the HTML card for one complaint
function makeCard(c) {
  var statusClass = c.status.replace(" ", "");   // "In Progress" -> "InProgress"
  return "<div class='card'>" +
           "<b>" + c.id + "</b> - " + c.category +
           " <span class='status " + statusClass + "'>" + c.status + "</span><br>" +
           safe(c.description) + "<br>" +
           "📍 " + safe(c.location) + " | 📅 " + c.date +
         "</div>";
}

// Citizen: show only MY complaints
function showMyComplaints() {
  var html = "";
  for (var i = 0; i < complaints.length; i++) {
    if (complaints[i].email == currentUser.email) {
      html += makeCard(complaints[i]);
    }
  }
  if (html == "") {
    html = "<p>You have not reported any problem yet.</p>";
  }
  document.getElementById("mineList").innerHTML = html;
  showPage("mine");
}


/* ---------- 9. TRACK BY ID ---------- */

function trackComplaint() {
  var id = document.getElementById("trackId").value.toUpperCase();
  var result = "<p>No complaint found with this ID.</p>";

  for (var i = 0; i < complaints.length; i++) {
    if (complaints[i].id == id) {
      result = makeCard(complaints[i]);
    }
  }
  document.getElementById("trackResult").innerHTML = result;
}


/* ---------- 10. ADMIN PANEL ---------- */

// Show all complaints with a dropdown to change the status
function showAllComplaints() {
  var html = "";

  for (var i = 0; i < complaints.length; i++) {
    var c = complaints[i];

    html += "<div class='card'>" +
              "<b>" + c.id + "</b> - " + c.category + "<br>" +
              safe(c.description) + "<br>" +
              "📍 " + safe(c.location) + " | 📅 " + c.date + "<br><br>" +
              "Status: " +
              "<select onchange=\"changeStatus('" + c.id + "', this.value)\">" +
                option(c.status, "Pending") +
                option(c.status, "Assigned") +
                option(c.status, "In Progress") +
                option(c.status, "Resolved") +
              "</select>" +
            "</div>";
  }

  if (html == "") {
    html = "<p>No complaints yet.</p>";
  }

  document.getElementById("count").innerHTML = "Total complaints: " + complaints.length;
  document.getElementById("adminList").innerHTML = html;
  showPage("admin");
}

// Make one <option>. If it is the current status, mark it "selected"
function option(current, name) {
  var selected = (current == name) ? " selected" : "";
  return "<option" + selected + ">" + name + "</option>";
}

// Admin changes the status of a complaint
function changeStatus(id, newStatus) {
  for (var i = 0; i < complaints.length; i++) {
    if (complaints[i].id == id) {
      complaints[i].status = newStatus;
    }
  }
  saveData();
  alert("Status updated to " + newStatus);
}


/* ---------- 11. START THE APP ---------- */

updateMenu();
showPage("home");
