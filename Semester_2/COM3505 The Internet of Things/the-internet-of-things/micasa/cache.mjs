// cache.mjs: cache navigation to file

import { JSDOM } from 'jsdom';
import fs from 'fs';

const fileIn = '../public/index.html';
const fileOut = 'cached-navig.html';
const html = fs.readFileSync(fileIn, 'utf8');
const dom = new JSDOM(html);
const document = dom.window.document;

async function saveDOM() {
  const htmlString = document.documentElement.outerHTML;
  fs.writeFileSync(fileOut, htmlString);
}


// (formerly in script.js): add navigation

let returnToTopButton = document.getElementById("returnToTop"); // redundant?
let listItems = "";

// used to be: window.onload = function () {
function addNavigation() {
  firstUlId();
  styleDivs(0, 15);
  styleList();
  addSidebar();
  addFooter();
  addItems();
  appendSideBarIds();
  addIdToBibliographyLink()
};

const moveUp = [
  { transform: 'translateY(-1vh)' },
];

const moveUpTiming = {
  duration: 2000,
  iterations: 1,
}

function scrollFunction() { // redundant?
  if (document.body.scrollTop > 20 || document.documentElement.scrollTop > 20) {
  } else {

  }
}

function topFunction() {
  document.body.scrollTop = 0; // For Safari
  document.documentElement.scrollTop = 0; // For Chrome, Firefox, IE and Opera
}

function styleDivs(start, end) {
  let divs = document.querySelectorAll("[data-number]");

  for (let i = 0; i < divs.length; i++) {
    let div = divs[i];
    let number = parseInt(div.getAttribute("data-number"));
    if (number >= start && number <= end) {
      div.style.backgroundColor = "#00d084" /*"#009966"*/;
      div.style.borderRadius = "5px";
    }
  }
}

function styleList() {
  let listWrapper = document.getElementById("TOC");
  let lis = listWrapper.getElementsByTagName("li");

  for (let i = 0; i < lis.length - 1; i++) {
    lis[i].style.listStyleType = "none";
    lis[i].style.display = "background-color: #000000";

    const specificLi = lis[i].querySelector(`li .toc-section-number`);
    const specificSpan = lis[i].querySelector(`span.toc-section-number`);
    const title = specificLi.parentNode.textContent;
    const number = specificSpan.textContent;
    const numbers = number.split(".").map(Number);

    if (numbers.length == 1) {
      let org_html = lis[i].innerHTML;
      if(false) console.log(org_html);

      let new_html = `<input type="checkbox" id="list-item-${i}">
       <label class="Label" for="list-item-${i}">
          <div class="label-text"></a>${title}</div>
            <img class="label-image" src="./icons/expand_more_FILL0_wght400_GRAD0_opsz48.svg" alt="v" />
       </label>` +
        "<ul>" + org_html + "</ul>";

      lis[i].innerHTML = "";
      lis[i].innerHTML = new_html;
    }
  }
}

function addSidebar() {
  let sideBar = document.createElement('div');
  let lis = document.getElementsByTagName("li");
  sideBar.classList.add("sideBar");
  let sideBar_html =
    `<nav role="navigation">` +
    '<div id="menuToggleBackground"></div>' +
    '<div id="menuToggle">' +
    '<input id="menuToggleInput" type="checkbox" />' +
    '<span></span>' +
    '<span></span>' +
    '<span></span>' +
    `<ul id="menu">` +
    `</ul>` +
    `</div>` +
    `</nav>`
  if(false) console.log(listItems);
  document.body.appendChild(sideBar);
  sideBar.innerHTML = sideBar_html;
}

function appendSideBarIds() {
  let sideBarDiv = document.getElementById("menu");
  let sidebarLis = sideBarDiv.getElementsByTagName("li");
  if(false) console.log(sidebarLis);
  for (let i = 0; i < sidebarLis.length - 1; i++) {
    const input = sidebarLis[i].querySelector('input[type="checkbox"]');
    const label = sidebarLis[i].querySelector('label');
    const newId = `sidebar-list-item-${i}`;

    if (input !== null) {
      input.removeAttribute("id");
      input.setAttribute("id", newId);
      label.setAttribute("for", newId);
    }
  }

  for (let i = 0; i < sidebarLis.length; i++) {
    let link = sidebarLis[i].querySelector("a");
    if (link && link.textContent === "Bibliography") {
      let org_html = sidebarLis[i].innerHTML;

      let new_html = `<input type="checkbox" id="list-item-b1">
      <label class="Label" for="list-item-b1">
         <div class="label-text"></a>Bibliography</div>
           <img class="label-image" src="./icons/expand_more_FILL0_wght400_GRAD0_opsz48.svg" alt="v" />
      </label>` +
        "<ul>" + org_html + "</ul>";

        sidebarLis[i].innerHTML = "";
        sidebarLis[i].innerHTML = new_html;
      sidebarLis[i].style.listStyleType = "none";
      break;
    }
  }

}

function addItems(event) {
  let list = document.getElementById("mainList");
  let clone = list.cloneNode(true);
  let sideBar = document.getElementById("menu");
  if(false) console.log("list" + list);
  sideBar.innerHTML = "";                            // Remove previous content
  sideBar.appendChild(clone);
}

function addFooter() {
  let footer = document.createElement('div');
  let footerHtml = `<div onclick="topFunction()" id="returnToTop"></div>`
  document.body.appendChild(footer);
  footer.innerHTML = footerHtml;
}

function addIdToBibliographyLink() {
  let listItems = document.querySelectorAll("li");

  for (let i = 0; i < listItems.length - 1; i++) {
    let link = listItems[i].querySelector("a");
    if (link && link.textContent === "Bibliography") {
      let org_html = listItems[i].innerHTML;

      let new_html = `<input type="checkbox" id="list-item-b2">
      <label class="Label" for="list-item-b2">
         <div class="label-text"></a>Bibliography</div>
           <img class="label-image" src="./icons/expand_more_FILL0_wght400_GRAD0_opsz48.svg" alt="v" />
      </label>` +
        "<ul>" + org_html + "</ul>";

      listItems[i].innerHTML = "";
      listItems[i].innerHTML = new_html;
      listItems[i].style.listStyleType = "none";
    }
  }
}

function firstUlId() {
  let listWrapper = document.getElementById("TOC");
  let uls = listWrapper.getElementsByTagName("ul");

  for (let i = 0; i < 2; i++) {
    uls[i].setAttribute("id", "mainList");
  }
}


// do the work
console.log('adding navigation');
addNavigation();
saveDOM();
console.log('navigation done');
