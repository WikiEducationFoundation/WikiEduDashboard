export const printArticleViewer = () => {
  const printWindow = window.open('', '_blank', '');
  const doc = printWindow.document;

  doc.open();
  doc.write(document.querySelector('#article-scrollbox-id').innerHTML);

  // copy over the stylesheets
  document.head.querySelectorAll('link, style').forEach((htmlElement) => {
    doc.head.appendChild(htmlElement.cloneNode(true));
  });
  doc.close();
  printWindow.focus();

  // Loading the stylesheets can take a while, so we wait a bit before printing.
  setTimeout(() => {
    printWindow.print();
  }, 500);
};
