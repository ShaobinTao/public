# Part 0 the background: projective geometry
##P27##
* treat line as a vector in homogenous coordinates
* Result 2.2 the intersection of two lines l and l' is the point x = l x l'. very creative to think of intersection point as cross product
##P28##
* Result 2.4 the line through two points x and x' is l = x cross x'
* for points (x1, x2, x3), those with last x3=0 are known as ideal points or points at infinity. The set of all ideal points may be written (x1, x2, 0)T (T means transpose to make it a column vector), with a particular point specified by the ratio x1/x2. The set lies on a single line, the line at infinity. Denoted by the vector l_inf = (0,0,1)T. 
*  a line l = (a, b, c)T intersects l_inf in the ideal point (b, -a, 0)T. (b, -a)T is tangent to the line, and orthogonal to the line normal (a,b), and so represents the line's direction. As line's direction varies, the intersection ideal point changes also. Thus, the line at inf can be thought of as the set of directions of lines in the plane.
##P30##
* duality principle: to any theorem of 2-dim projective geom, there corresponds a dual theorem, which may be derived by interchanging the roles of points and lines in the original theorem.
* a conic in in-homogenuous coordinates is  a x^2 + b x y + c y^2 + d x + e y + f = 0
  to homogenize it, let x = x1/x3, y=x2/x3
  ax1 ^2 + bx1x2 + cx2 ^2 + dx1x3 + ex2x3 + fx3 ^2= 0
  matrix C in eq 2.3 is a homogenous repr of a conic
  
  the conic has 5 DOF. (totally 6 coeff, but it can be divided by one of the coefficients to get 5). In other words, 5 points define a conic
##P31##
  
   
