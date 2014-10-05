try(destroyDialog ImageCompHelper.ro)catch()


struct ImageCompHelper (
	/***Creates lines in the active viewport that act as a visual guide for image composition.

	They are created as a render effect, so no camera is needed.
	Just check/uncheck the buttons to display the lines.

	Update 20/12/2012:
		- Added the golden spiral (similar to Fibonacci spiral).
		Note: This by nature is fixed to an aspect of 1:1.618
		- Color selection now reflects instantly

	Update 21/10/2012: Added option to pick custom colors

	Update 25/11/2010: Fixed bug with non working playanimation-button.
		Added custom overlay options and did some UI changes.

	ToDo:
		-- Make spiral work in portrait mode

	Written by Christoph Buelter 23.11.10
	www.cbuelter.de

	***/
	goldenRatio = 1.6180,
	inverseGoldenRatio = 0.618047,

	rectangles = #(),  -- Holds sub rectangles for golden spiral.
	spiralMode = 0,  -- Determine orientation of golden spiral.

	fn drawCircle origin radius startAngle endAngle step clr = (
		points = #()
		for i in startAngle to endAngle by step do (
			x = origin.x + radius * sin i
			y = origin.y + radius * cos i
			p = [x,y,0]
			append points p
		)

		for j=1 to (points.count-1) do (
			gw.wPolyline #(points[j], points[j+1]) false rgb:#(clr,clr)
		)
	),

	fn drawRectangle rect clr = (
		clrArray = #(clr,clr,clr,clr)
		gw.wPolyline #(rect[1], rect[2], rect[3], rect[4]) true rgb:clrArray
	),

	fn calcSubRectangle rect blendFactor times mode = (
		/***Gets a rectangle, calculates a new one that is part of the old.

		This fn does not return anything, but instead
		changes the 'rectangles' array.

		***/
		while times > 0 do (
			case mode of (
				-- Choose order of vertices for calculation.
				-- Basically there are just two working modes (each twice).
				-- They however are different in creation order.
				0: (A = rect[1]; B = rect[2]; C = rect[3]; D = rect[4])
				1: (C = rect[1]; D = rect[2]; A = rect[3]; B = rect[4])
				2: (C = rect[1]; D = rect[2]; A = rect[3]; B = rect[4])
				3: (A = rect[1]; B = rect[2]; C = rect[3]; D = rect[4])
			)

			eX = B.x + blendFactor * (C.x - B.x)
			eY = B.y + blendFactor * (C.y - B.y)
			E = [eX, eY, 0]

			fX = A.x + blendFactor * (D.x - A.x)
			fY = A.y + blendFactor * (D.y - A.y)
			F = [fX, fY, 0]

			-- Choose order for newRect.
			-- Create new rectangle with different
			-- vertex order, append and repeat.
			case this.spiralMode of (
				0 : newRect = #(E,C,D,F)
				1 : newRect = #(E,C,D,F)
				2 : newRect = #(D,F,E,C)
				3 : newRect = #(D,F,E,C)
			)

			append this.rectangles newRect

			times -= 1

			if times > 0 do
				rect = newRect
		)
	),

	fn drawGoldenSpiral fieldX fieldY offsetX offsetY clr = (
		-- Setup
		if fieldX > (fieldY * this.goldenRatio) then (
			local w = fieldY * this.goldenRatio
			local h = fieldY
		)
		else (
			local w = fieldX
			local h = fieldX / this.goldenRatio
		)

		local oriX = fieldX / 2 - w / 2  -- Origin x
		local oriY = fieldY / 2 - h / 2  -- Origin y

		-- 1 means 360 points are connected to
		-- draw a circle, 2 means 180 etc.
		local step = 3

		-- Calculation:

		-- Main rectangle
		append this.rectangles #([oriX + offsetX, oriY + offsetY + h, 0], [oriX + offsetX, oriY + offsetY, 0], [oriX + offsetX + w, oriY + offsetY, 0], [oriX + offsetX + w, oriY + offsetY + h, 0])

		calcSubRectangle this.rectangles[1] this.inverseGoldenRatio 12 this.spiralMode

		-- Look up starting orientation to draw circles correctly.
		local circleStart
		local originIndex
		local rotationDirection

		-- Note: Lots of experimentation behind these settings...
		case this.spiralMode of (
			0 : (originIndex = 4; circleStart = 180; rotationDirection = 1)
			1 : (originIndex = 1; circleStart = 90; rotationDirection = 0)
			2 : (originIndex = 2; circleStart = 360; rotationDirection = 1)
			3 : (originIndex = 3; circleStart = 270; rotationDirection = 0)
		)

		-- Draw:
		for k = 1 to this.rectangles.count do (
			local r = this.rectangles[k]

			-- Uncomment next line to only draw the spiral without rectangles:
			drawRectangle r (clr / 2.5)

			if k > 1 do (  -- No circle around main rectangle, so skip k==1
				local prevR = this.rectangles[k-1]
				local degrees = 90  -- Quarter circles is what we want

				-- CW or CCW drawing of circle.
				if rotationDirection == 1 then (
					drawCircle r[originIndex] (distance prevR[1] prevR[2]) circleStart (circleStart + degrees) step clr

					circleStart -= degrees  -- Decrease
					if circleStart <= 0 do circleStart = 360
				)
				else if rotationDirection == 0 do (
					drawCircle r[originIndex] (distance prevR[1] prevR[2]) circleStart (circleStart + degrees) step clr

					circleStart += degrees  -- Increase
					if circleStart >= 360 do circleStart = 0
				)
			)
		)

		-- Reset rectangles!
		this.rectangles = #()
	),

	fn drawGoldenRatio fieldX fieldY offsetX offsetY clr = (
		clrArray = #(clr, clr)
		gldX = fieldX as float / this.goldenRatio
		gldY = fieldY as float / this.goldenRatio
		gw.wPolyline #([gldX+offsetX, 0+offsetY, 0], [gldX+offsetX, fieldY+offsetY-1, 0]) true rgb:clrArray
		gw.wPolyline #([fieldX-gldX+offsetX, 0+offsetY, 0], [fieldX-gldX+offsetX, fieldY+offsetY-1, 0]) true rgb:clrArray
		gw.wPolyline #([0+offsetX, gldY+offsetY, 0], [fieldX+offsetX-1, gldY+offsetY, 0]) true rgb:clrArray
		gw.wPolyline #([0+offsetX, fieldY-gldY+offsetY, 0], [fieldX+offsetX-1, fieldY-gldY+offsetY, 0]) true rgb:clrArray
	),

	fn drawCross fieldX fieldY offsetX offsetY clr = (
		clrArray = #(clr, clr)
		b = fieldX / 2
		h = fieldY / 2
		gw.wPolyline #([b+offsetX, 0+offsetY, 0], [b+offsetX, fieldY+offsetY-1, 0]) true rgb:clrArray
		gw.wPolyline #([0+offsetX, h+offsetY, 0], [fieldX+offsetX-1, h+offsetY, 0]) true rgb:clrArray
	),

	fn drawCustomLines divX divY fieldX fieldY offsetX offsetY clr = (
		clrArray = #(clr, clr)

		if divX > 0 do (
			b = fieldX / (divX+1) as float
			for i=1 to divX do (
				gw.wPolyline #([i*b+offsetX, 0+offsetY, 0], [i*b+offsetX, fieldY+offsetY-1, 0]) true rgb:clrArray
			)
		)

		if divY > 0 do (
			h = fieldY / (divY+1) as float
			for i=1 to divY do (
				gw.wPolyline #([0+offsetX, i*h+offsetY, 0], [fieldX+offsetX-1, i*h+offsetY, 0]) true rgb:clrArray
			)
		)
	),

	fn drawThirds fieldX fieldY offsetX offsetY clr = (
		clrArray = #(clr, clr)
		b = fieldX / 3
		h = fieldY / 3
		gw.wPolyline #([b+offsetX, 0+offsetY, 0], [b+offsetX, 3*h+offsetY-1, 0]) true rgb:clrArray
		gw.wPolyline #([2*b+offsetX, 0+offsetY, 0], [2*b+offsetX, 3*h+offsetY-1, 0]) true rgb:clrArray
		gw.wPolyline #([0+offsetX, h+offsetY, 0], [3*b+offsetX-1, h+offsetY, 0]) true rgb:clrArray
		gw.wPolyline #([0+offsetX, 2*h+offsetY, 0], [3*b+offsetX-1, 2*h+offsetY, 0]) true rgb:clrArray
	),

	fn drawDiagonals  fieldX fieldY offsetX offsetY clr = (
		clrArray = #(clr, clr)
		gw.wPolyline #([0+offsetX, 0+offsetY, 0], [fieldX+offsetX, fieldY+offsetY, 0]) true rgb:clrArray
		gw.wPolyline #([0+offsetX, fieldY+offsetY, 0], [fieldX+offsetX, 0+offsetY, 0]) true rgb:clrArray
	),

	fn prepareAndDraw = (
		/***This is the main execution function that lives in the callback.

		Note: It gets its input directly from the GUI, so changes are reflected instantly.

		***/
		main = ImageCompHelper
		gui = ImageCompHelper.ro

		if gui.ckb_thirds.checked or gui.ckb_golden.checked or \
		gui.ckb_cross.checked or gui.ckb_diagonals.checked or \
		gui.ckb_custom.checked or gui.ckb_spiral.checked do (

			if not displaysafeframes do
				displaysafeframes = true

			--General calculation of drawing field:
			local winX = gw.getWinSizeX()
			local winY = gw.getWinSizeY()
			local winAspect = winX as float / winY as float
			local renAspect = renderWidth as float / renderHeight as float

			local offsetX = 0
			local offsetY = 0
			local fieldX = 0
			local fieldY = 0

			-- If width > height:
			if winAspect > renAspect then (
				fieldFactor = winY as float / renderHeight as float
				fieldY = winY
				fieldX = fieldFactor * renderWidth
				offsetX = (winX - fieldX)/2 + 1
			)

			--If height > width:
			else (
				fieldFactor = winX as float / renderWidth as float
				fieldX = winX
				fieldY = fieldFactor * renderHeight
				offsetY = (winY - fieldY)/2 + 1
			)

			-- Draw:
			if gui.ckb_custom.checked do
				main.drawCustomLines gui.spn_XDivs.value gui.spn_YDivs.value fieldX fieldY offsetX offsetY gui.cp_custom.color

			if gui.ckb_spiral.checked do
				main.drawGoldenSpiral fieldX fieldY offsetX offsetY gui.cp_spiral.color

			if gui.ckb_golden.checked do
				main.drawGoldenRatio fieldX fieldY offsetX offsetY gui.cp_golden.color

			if gui.ckb_thirds.checked do
				main.drawThirds fieldX fieldY offsetX offsetY gui.cp_thirds.color

			if gui.ckb_diagonals.checked do
				main.drawDiagonals fieldX fieldY offsetX offsetY gui.cp_diagonals.color

			if gui.ckb_cross.checked do
				main.drawCross fieldX fieldY offsetX offsetY gui.cp_cross.color

			gw.enlargeUpdateRect #whole
			gw.updateScreen()
			redrawViews()
		)
	),

	ro = rollout ro "Overlay" width:112 height:194 (

		local self  -- Parent struct reference
		local colorDivisor = 2.5

		colorPicker cp_custom "" pos:[-1,52] width:23 height:22 color:(color 0 255 0)
		colorPicker cp_thirds "" pos:[-1,77] width:23 height:22 color:(color 255 255 0)
		colorPicker cp_diagonals "" pos:[-1,100] width:23 height:22 color:(color 255 0 0)
		colorPicker cp_golden "" pos:[-1,123] width:23 height:22 color:(color 255 110 0)
		colorPicker cp_spiral "" pos:[-1,147] width:23 height:22 color:(color 255 255 255)
		colorPicker cp_cross "" pos:[-1,171] width:23 height:22 color:(color 0 0 155)
		checkbutton ckb_thirds "Rule of Thirds" pos:[23,77] width:88 height:22 toolTip:"" checked:false
		checkbutton ckb_golden "Golden Ratio" pos:[23,123] width:88 height:22 toolTip:"" checked:false
		checkbutton ckb_cross "Center Cross" pos:[23,171] width:88 height:22 toolTip:"" checked:false
		checkbutton ckb_diagonals "Diagonals" pos:[23,100] width:88 height:22 toolTip:"" checked:false
		checkbutton ckb_custom "Custom" pos:[23,52] width:86 height:22 toolTip:"" checked:false
		checkbutton ckb_spiral "Golden Spiral" pos:[23,147] width:88 height:22 toolTip:"Rightclick to flip spiral" checked:false
		GroupBox grp_custom "Custom:" pos:[1,0] width:110 height:76
		spinner spn_XDivs "X Divs:" pos:[27,15] width:80 height:16 range:[0,999,4] type:#integer scale:1
		spinner spn_YDivs "Y Divs:" pos:[27,33] width:80 height:16 range:[0,999,4] type:#integer scale:1

		fn updateHighlightColors force:true = (
			/***When user changes color, update the checkboxes.***/
			ckb_golden.highlightColor = cp_golden.color / colorDivisor
			ckb_custom.highlightColor = cp_custom.color / colorDivisor
			ckb_cross.highlightColor = cp_cross.color / colorDivisor
			ckb_diagonals.highlightColor = cp_diagonals.color / colorDivisor
			ckb_thirds.highlightColor = cp_thirds.color / colorDivisor
			ckb_spiral.highlightColor = cp_spiral.color / colorDivisor

			-- Force update of GUI by flipping checkbox states twice:
			if force do (
				ckb_golden.checked = not ckb_golden.checked
				ckb_custom.checked = not ckb_custom.checked
				ckb_cross.checked = not ckb_cross.checked
				ckb_diagonals.checked = not ckb_diagonals.checked
				ckb_thirds.checked = not ckb_thirds.checked
				ckb_spiral.checked = not ckb_spiral.checked

				ckb_golden.checked = not ckb_golden.checked
				ckb_custom.checked = not ckb_custom.checked
				ckb_cross.checked = not ckb_cross.checked
				ckb_diagonals.checked = not ckb_diagonals.checked
				ckb_thirds.checked = not ckb_thirds.checked
				ckb_spiral.checked = not ckb_spiral.checked
			)
		)

		on ro close do (
			self.unregisterCallbacks()
		)

		on ckb_thirds changed theState do (
			redrawViews()
		)

		on ckb_golden changed theState do (
			redrawViews()
		)

		on ckb_cross changed theState do (
			redrawViews()
		)

		on ckb_diagonals changed theState do (
			redrawViews()
		)

		on ckb_custom changed theState do (
			redrawViews()
		)

		on ckb_spiral changed theState do (
			redrawViews()
		)

		on ckb_spiral rightclick do (
			self.spiralMode += 1
			if self.spiralMode > 3 do
				self.spiralMode = 0
			redrawViews()
		)
		on cp_thirds changed clr do (
			updateHighlightColors()
			redrawViews()
		)

		on cp_golden changed clr do (
			updateHighlightColors()
			redrawViews()
		)

		on cp_cross changed clr do (
			updateHighlightColors()
			redrawViews()
		)

		on cp_diagonals changed clr do (
			updateHighlightColors()
			redrawViews()
		)

		on cp_custom changed clr do (
			updateHighlightColors()
			redrawViews()
		)

		on cp_spiral changed clr do (
			updateHighlightColors()
			redrawViews()
		)

		on spn_XDivs changed theValue do (
			redrawViews()
		)

		on spn_YDivs changed theValue do (
			redrawViews()
		)
	),

	fn registerCallbacks = (
		unregisterRedrawViewsCallback this.prepareAndDraw
		registerRedrawViewsCallback this.prepareAndDraw
	),

	fn unregisterCallbacks = (
		unregisterRedrawViewsCallback this.prepareAndDraw
		completeRedraw()
	),

	fn show = (
		this.registerCallbacks()

		createDialog this.ro
		this.ro.self = this
		this.ro.updateHighlightColors()

		-- Force display of safeFrame on script startup:
		if not displaysafeframes do
			displaysafeframes = true
		redrawViews()
	)
)


ImageCompHelper = ImageCompHelper()
ImageCompHelper.show()

