const toggleAccordian = (id) => {
  const element = document.getElementById(id);
  if (element.className.indexOf('collapsed') === -1) {
    element.className = element.className.replace('expanded', 'collapsed');
  } else {
    element.className = element.className.replace('collapsed', 'expanded');
  }
};

window.toggleAccordian = toggleAccordian;
