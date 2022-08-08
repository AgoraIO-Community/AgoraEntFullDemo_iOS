function init() {
  Array.from(document.getElementsByClassName("entertainment")).map(
    (val, index) => {
      val.onclick = () => {
          if(index != 1) {
            window.location.href = `entertainment.html?type=${
              index + 1
            }`;
          }
          else {
              window.alert("文档即将上线，敬请期待");
          }
      };
    }
  );
  Array.from(document.getElementsByClassName("proWrap")).map((val, index) => {
    val.onclick = () => {
      window.location.href = `product.html?type=${index + 1}`;
    };
  });
}
init();
