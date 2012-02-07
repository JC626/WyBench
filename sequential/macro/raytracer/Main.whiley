import * from whiley.lang.System

void ::main(System.Console sys):
    sphere = Sphere.Sphere(Point.Point(20,20,20),10.0)
    ray = Ray.Ray(Point.Point(1,1,1),Vector.Vector(1,1,1))
    r = Sphere.intersect(sphere,ray)
    if r != null:
        p0,p1 = r
        sys.out.println("P0 = " + Point.toString(p0))
        sys.out.println("P1 = " + Point.toString(p1))
    else:
        sys.out.println("no intersection")

    t = Sphere.solveQuadratic(2,-4,-3,0.0001)
    if t != null:
        p0,p1 = t
        sys.out.println("T0 = " + Real.toDecimal(p0,5))
        sys.out.println("T1 = " + Real.toDecimal(p1,5))        