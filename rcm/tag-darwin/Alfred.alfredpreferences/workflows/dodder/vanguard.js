
function() {
  getNth = function(n) {
    return document.querySelectorAll(
      `
      .PositionsTable-assetClass
      .sc-StackableTable-bodyRow
      .sc-StackableTable-bodyRow
      .sc-StackableTable-bodyCell:nth-child(${n})
      .sc-StackableTable-bodyCellContent
      `
    );
  };

  const symbols = Array.from(
    getNth(3),
    x => x.textContent.trim()
  );

  const shares = Array.from(
    getNth(4),
    function(x) {
      const t = x.textContent.trim();
      return t.substr(0, t.lastIndexOf(' '));
    }
  );

  return symbols.map(function(e, i) {
    return [e, shares[i]];
  });
}()
