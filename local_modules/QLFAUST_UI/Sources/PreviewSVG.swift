//
//  SVGPreview.swift
//  QLFAUST
//
//  Created by alex on 24/03/2025.
//

import SwiftUI

import SVGView

public struct PreviewSVG: View {
    public var body: some View { render }
    
    let svgString : String
    let error: String
    
    public init(svgString : String) {
        do {
            self.svgString = svgString
            error = ""
        }
        catch let err {
            self.error = "exception: "+err.localizedDescription;
        }
    }
    
    @ViewBuilder
    private var render : some View {
        VStack {
            
            SVGView(string: svgString)
                .frame(minWidth: 320, maxWidth: .infinity, minHeight: 240, maxHeight: .infinity)
                .padding()
                .drawingGroup()
        }
    }
}

// MARK: -

struct SVGView_Preview: PreviewProvider {
    static var previews: some View { PreviewSVG(svgString: #"""
<?xml version="1.0"?>
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 88.000000 72.000000" width="44.000000mm" height="36.000000mm" version="1.1">
<rect x="1.000000" y="1.000000" width="87.000000" height="71.000000" rx="0" ry="0" style="stroke:none;fill:#cccccc;"/>
<rect x="0.000000" y="0.000000" width="87.000000" height="71.000000" rx="0" ry="0" style="stroke:none;fill:#ffffff;"/>
<text x="10.000000" y="7.000000" font-family="Arial" font-size="7"></text>
<rect x="33.000000" y="25.000000" width="24.000000" height="24.000000" rx="0" ry="0" style="stroke:none;fill:#cccccc;"/>
<rect x="32.000000" y="24.000000" width="24.000000" height="24.000000" rx="0" ry="0" style="stroke:none;fill:#4B71A1;"/>
<text x="44.000000" y="38.000000" font-family="Arial" font-size="7" text-anchor="middle" fill="#FFFFFF">sin</text>
<circle cx="34.000000" cy="26.000000" r="1"/>
<line x1="29.000000" y1="35.000000" x2="32.000000" y2="36.000000"  transform="rotate(0.000000,32.000000,36.000000)" style="stroke: black; stroke-width:0.25;"/>
<line x1="29.000000" y1="37.000000" x2="32.000000" y2="36.000000"  transform="rotate(0.000000,32.000000,36.000000)" style="stroke: black; stroke-width:0.25;"/>
<line x1="15.000000" y1="15.000000" x2="15.000000" y2="57.000000"  style="stroke: black; stroke-linecap:round; stroke-width:0.25; stroke-dasharray:3,3;"/>
<line x1="15.000000" y1="57.000000" x2="73.000000" y2="57.000000"  style="stroke: black; stroke-linecap:round; stroke-width:0.25; stroke-dasharray:3,3;"/>
<line x1="73.000000" y1="57.000000" x2="73.000000" y2="15.000000"  style="stroke: black; stroke-linecap:round; stroke-width:0.25; stroke-dasharray:3,3;"/>
<line x1="15.000000" y1="15.000000" x2="20.000000" y2="15.000000"  style="stroke: black; stroke-linecap:round; stroke-width:0.25; stroke-dasharray:3,3;"/>
<line x1="49.025000" y1="15.000000" x2="73.000000" y2="15.000000"  style="stroke: black; stroke-linecap:round; stroke-width:0.25; stroke-dasharray:3,3;"/>
<text x="20.000000" y="17.000000" font-family="Arial" font-size="7">process</text>
<line x1="75.000000" y1="35.000000" x2="78.000000" y2="36.000000"  transform="rotate(0.000000,78.000000,36.000000)" style="stroke: black; stroke-width:0.25;"/>
<line x1="75.000000" y1="37.000000" x2="78.000000" y2="36.000000"  transform="rotate(0.000000,78.000000,36.000000)" style="stroke: black; stroke-width:0.25;"/>
<line x1="10.000000" y1="36.000000" x2="20.000000" y2="36.000000"  style="stroke:black; stroke-linecap:round; stroke-width:0.25;"/>
<line x1="20.000000" y1="36.000000" x2="24.000000" y2="36.000000"  style="stroke:black; stroke-linecap:round; stroke-width:0.25;"/>
<line x1="24.000000" y1="36.000000" x2="28.000000" y2="36.000000"  style="stroke:black; stroke-linecap:round; stroke-width:0.25;"/>
<line x1="28.000000" y1="36.000000" x2="28.000000" y2="36.000000"  style="stroke:black; stroke-linecap:round; stroke-width:0.25;"/>
<line x1="28.000000" y1="36.000000" x2="32.000000" y2="36.000000"  style="stroke:black; stroke-linecap:round; stroke-width:0.25;"/>
<line x1="56.000000" y1="36.000000" x2="60.000000" y2="36.000000"  style="stroke:black; stroke-linecap:round; stroke-width:0.25;"/>
<line x1="60.000000" y1="36.000000" x2="60.000000" y2="36.000000"  style="stroke:black; stroke-linecap:round; stroke-width:0.25;"/>
<line x1="60.000000" y1="36.000000" x2="64.000000" y2="36.000000"  style="stroke:black; stroke-linecap:round; stroke-width:0.25;"/>
<line x1="64.000000" y1="36.000000" x2="68.000000" y2="36.000000"  style="stroke:black; stroke-linecap:round; stroke-width:0.25;"/>
<line x1="68.000000" y1="36.000000" x2="78.000000" y2="36.000000"  style="stroke:black; stroke-linecap:round; stroke-width:0.25;"/>
</svg>

"""#) }
}
