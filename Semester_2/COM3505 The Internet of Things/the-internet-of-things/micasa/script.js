// script.js: add navigation

window.onscroll = function () { scrollFunction() };

/*
// not used, now done by cache.mjs
window.onload = function () {
  firstUlId();
  styleDivs(0, 15);
  styleList();
  addSidebar();
  addFooter();
  addItems();
  appendSideBarIds();
  addIdToBibliographyLink()
};

// not sure what these were for...
const moveUp = [
  { transform: 'translateY(-1vh)' },
];
const moveUpTiming = {
  duration: 2000,
  iterations: 1,
}
*/

function scrollFunction() {
  if (document.body.scrollTop > 20 || document.documentElement.scrollTop > 20) {
  } else {

  }
}

function topFunction() {
  document.body.scrollTop = 0; // For Safari
  document.documentElement.scrollTop = 0; // For Chrome, Firefox, IE and Opera
}

// all moved to cache.mjs:
//
// function styleDivs(start, end) {
//   let divs = document.querySelectorAll("[data-number]");
//
//   for (let i = 0; i < divs.length; i++) {
//     let div = divs[i];
//     let number = parseInt(div.getAttribute("data-number"));
//     if (number >= start && number <= end) {
//       div.style.backgroundColor = "#00d084" /*"#009966"*/;
//       div.style.borderRadius = "5px";
//     }
//   }
// }
//
// function styleList() {
//   let listWrapper = document.getElementById("TOC");
//   let lis = listWrapper.getElementsByTagName("li");
//
//   for (let i = 0; i < lis.length - 1; i++) {
//     lis[i].style.listStyleType = "none";
//     lis[i].style.display = "background-color: #000000";
//
//     const specificLi = lis[i].querySelector(`li .toc-section-number`);
//     const specificSpan = lis[i].querySelector(`span.toc-section-number`);
//     const title = specificLi.parentNode.textContent;
//     const number = specificSpan.textContent;
//     const numbers = number.split(".").map(Number);
//
//     if (numbers.length == 1) {
//       org_html = lis[i].innerHTML;
//       console.log(org_html);
//
//       new_html = `<input type="checkbox" id="list-item-${i}">
//        <label class="Label" for="list-item-${i}">
//           <div class="label-text"></a>${title}</div>
//             <img class="label-image" src="./icons/expand_more_FILL0_wght400_GRAD0_opsz48.svg" alt="v" />
//        </label>` +
//         "<ul>" + org_html + "</ul>";
//
//       lis[i].innerHTML = "";
//       lis[i].innerHTML = new_html;
//     }
//   }
// }
//
// function addSidebar() {
//   let sideBar = document.createElement('div');
//   let lis = document.getElementsByTagName("li");
//   sideBar.classList.add("sideBar");
//   sideBar_html =
//     `<nav role="navigation">` +
//     '<div id="menuToggleBackground"></div>' +
//     '<div id="menuToggle">' +
//     '<input id="menuToggleInput" type="checkbox" />' +
//     '<span></span>' +
//     '<span></span>' +
//     '<span></span>' +
//     `<ul id="menu">` +
//     `</ul>` +
//     `</div>` +
//     `</nav>`
//   console.log(listItems);
//   document.body.appendChild(sideBar);
//   sideBar.innerHTML = sideBar_html;
// }
//
// function appendSideBarIds() {
//   let sideBarDiv = document.getElementById("menu");
//   let sidebarLis = sideBarDiv.getElementsByTagName("li");
//   console.log(sidebarLis);
//   for (let i = 0; i < sidebarLis.length - 1; i++) {
//     const input = sidebarLis[i].querySelector('input[type="checkbox"]');
//     const label = sidebarLis[i].querySelector('label');
//     const newId = `sidebar-list-item-${i}`;
//
//     if (input !== null) {
//       input.removeAttribute("id");
//       input.setAttribute("id", newId);
//       label.setAttribute("for", newId);
//     }
//   }
//
//   for (let i = 0; i < sidebarLis.length; i++) {
//     let link = sidebarLis[i].querySelector("a");
//     if (link && link.textContent === "Bibliography") {
//       org_html = sidebarLis[i].innerHTML;
//
//       new_html = `<input type="checkbox" id="list-item-b1">
//       <label class="Label" for="list-item-b1">
//          <div class="label-text"></a>Bibliography</div>
//            <img class="label-image" src="./icons/expand_more_FILL0_wght400_GRAD0_opsz48.svg" alt="v" />
//       </label>` +
//         "<ul>" + org_html + "</ul>";
//
//         sidebarLis[i].innerHTML = "";
//         sidebarLis[i].innerHTML = new_html;
//       sidebarLis[i].style.listStyleType = "none";
//       break;
//     }
//   }
//
// }
//
// function addItems(event) {
//   let list = document.getElementById("mainList");
//   let clone = list.cloneNode(true);
//   let sideBar = document.getElementById("menu");
//   console.log("list" + list);
//   sideBar.innerHTML = "";                            // Remove previous content
//   sideBar.appendChild(clone);
// }
//
// function addFooter() {
//   let footer = document.createElement('div');
//   footerHtml = `<div onclick="topFunction()" id="returnToTop"></div>`
//   document.body.appendChild(footer);
//   footer.innerHTML = footerHtml;
// }
//
// function addIdToBibliographyLink() {
//   let listItems = document.querySelectorAll("li");
//
//   for (let i = 0; i < listItems.length - 1; i++) {
//     let link = listItems[i].querySelector("a");
//     if (link && link.textContent === "Bibliography") {
//       org_html = listItems[i].innerHTML;
//
//       new_html = `<input type="checkbox" id="list-item-b2">
//       <label class="Label" for="list-item-b2">
//          <div class="label-text"></a>Bibliography</div>
//            <img class="label-image" src="./icons/expand_more_FILL0_wght400_GRAD0_opsz48.svg" alt="v" />
//       </label>` +
//         "<ul>" + org_html + "</ul>";
//
//       listItems[i].innerHTML = "";
//       listItems[i].innerHTML = new_html;
//       listItems[i].style.listStyleType = "none";
//     }
//   }
// }
//
// function firstUlId() {
//   let listWrapper = document.getElementById("TOC");
//   let uls = listWrapper.getElementsByTagName("ul");
//
//   for (let i = 0; i < 2; i++) {
//     uls[i].setAttribute("id", "mainList");
//   }
// }
//
