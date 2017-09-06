(function () {

  var renderers = {
    circle: function (data) {
      var c = new paper.Path.Circle({ center: paper.view.center,
                                      radius: data.radius,
                                      fillColor: "white"
                                    });
      return c;
    },
    rect: function (data) {
      var r = new paper.Path.Rectangle({ point: paper.view.center.subtract([data.width / 2, data.height / 2]),
                                         size: [data.width, data.height],
                                         fillColor: "white"
                                       });
      return r;
    },
    empty: function () {
      return (new paper.Path());
    },
    union: function (data) {
      var left = render(data.operands[0]),
          right = render(data.operands[1]);
      var sum = left.unite(right);
      left.remove();
      right.remove();
      return sum;
    },
    difference: function (data) {
      var left = render(data.operands[0]),
          right = render(data.operands[1]);

      var diff = left.subtract(right);
      left.remove();
      right.remove();
      return diff;
    }
  };

  var render = function (d) {
    var def = renderers[d.definition.type](d.definition);
    def.transform(new paper.Matrix(d.transformation));
    return def;
  };

  window.addEventListener("message", function (evt) {
    var data = JSON.parse(evt.data.data);
        canvas = document.getElementById("drawing");
    paper.setup(canvas);
    paper.project.clear();
    paper.view.center = [0,0];
    render(data);
    paper.view.draw();
  });
}());
