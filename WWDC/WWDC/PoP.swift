//
//  PoP.swift
//  WWDC
//
//  Created by Jihaha kim on 2024/06/19.
//

import Foundation

//## Replacing classes in OOP with protocols
//
//We're going to model a diagramming app where users can drag and drop shapes on a drawing surface and then interact with those shapes. We're building the document and display model.
//
//First, a primitive "renderer" which just prints out drawing commands:

struct Renderer {
  func move(to point: CGPoint) {
    print("Move to (\(point.x), \(point.y))")
  }

  func line(to point: CGPoint) {
    print("Line to (\(point.x), \(point.y))")
  }

  func arc(at center: CGPoint, radius: CGFloat, startAngle: CGFloat, endAngle: CGFloat) {
    print("Arc at \(center), radius: \(radius), startAngle: \(startAngle), endAngle: \(endAngle)")
  }
}

//Next, a `Drawable` protocol which provides a common interface for all our drawing elements:

protocol Drawable {
  func draw(using renderer: Renderer)
}

//Then, shapes like polygons. Notice that this is a value type built out of another value type, `CGPoint`:

struct Polygon: Drawable {
  var corners = [CGPoint]()

  func draw(using renderer: Renderer) {
    renderer.move(to: corners.last!)

    for point in corners {
      renderer.line(to: point)
    }
  }
}

//Here's a circle, which is also a value type built out of other value types:

struct Circle: Drawable {
  var center: CGPoint
  var radius: CGFloat

  func draw(using renderer: Renderer) {
    renderer.arc(at: center, radius: radius, startAngle: 0.0, endAngle: twoPi)
  }
}

//Now, we can build a diagram out of circles and polygons:

struct Diagram: Drawable {
  var elements = [Drawable]()

  func draw(using renderer: Renderer) {
    for element in elements {
      element.draw(using: renderer)
    }
  }
}

//### Let's test it
//
//Here's the test with some curiously specific values:

var circle = Circle(center: CGPoint(x: 187.5, y: 333.5), radius: 93.75)

var triangle = Polygon(corners: [
  CGPoint(x: 187.5, y: 427.25),
  CGPoint(x: 268.69, y: 286.625),
  CGPoint(x: 106.31, y: 286.625)
])

var diagram = Diagram(elements: [circle, triangle])
diagram.draw(using: Renderer())

//The output, clearly an equilateral triangle with a circle inscribed in a circle (meant to be non-obvious/a joke):

//$ ./test
//Arc at (187.5, 333.5), radius: 93.75, startAngle: 0.0, endAngle: 6.28318530717959
//Move to (106.310118395209, 286.625)
//Line to (187.5, 427.25)
//Line to (268.689881604791, 286.625)
//Line to (106.310118395209, 286.625)

//There's a good use for a text renderer: testing! We can easily see check if values change. Let's change `Renderer` to a protocol:

protocol Renderer {
  func move(to point: CGPoint)
  func line(to point: CGPoint)
  func arc(at center: CGPoint, radius: CGFloat, startAngle: CGFloat, endAngle: CGFloat)
}

struct TestRenderer: Renderer {
  func move(to point: CGPoint) {
    print("Move to (\(point.x), \(point.y))")
  }

  func line(to point: CGPoint) {
    print("Line to (\(point.x), \(point.y))")
  }

  func arc(at center: CGPoint, radius: CGFloat, startAngle: CGFloat, endAngle: CGFloat) {
    print("Arc at \(center), radius: \(radius), startAngle: \(startAngle), endAngle: \(endAngle)")
  }
}

//### Making the real renderer
//
//Now that we have our protocol defined, it's easy to turn Core Graphics into a renderer--we don't even need a new type. Recall that this makes use of *retroactive modeling*:

extension CGContext: Renderer {
  func move(to point: CGPoint) {
    CGContextMoveToPoint(self, position.x, position.y)
  }

  func line(to point: CGPoint) {
    CGContextAddLineToPoint(self, position.x, position.y)
  }

  func arc(at center: CGPoint, radius: CGFloat, startAngle: CGFloat, endAngle: CGFloat) {
    let arc = CGPathCreateMutable()
    CGPathAddArc(arc, nil, center.x, center.y, radius, startAngle, endAngle, true)
    CGContextAddPath(self, arc)
  }
}
