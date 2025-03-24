// import("stdfaust.lib");

h1 = hslider("hslider", 0.5, 0, 1, 0.01);
v1 = vslider("vslider", 0.5, 0, 1, 0.01);
n1 = nentry("nentry", 0.5, 0, 1, 0.01);
b1 = nentry("button", 0.5, 0, 1, 0.01);
c1 = nentry("checkbox", 0.5, 0, 1, 0.01);

hg1 = hgroup("h1", v1 + b1);
vg1 = vgroup("v1", hg1 + n1 + h1);

process = _ * vg1 + h1;//+h1 + v1 + n1 + b1 + c1;
