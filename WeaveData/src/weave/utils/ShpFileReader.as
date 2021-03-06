/*
    Weave (Web-based Analysis and Visualization Environment)
    Copyright (C) 2008-2011 University of Massachusetts Lowell

    This file is a part of Weave.

    Weave is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License, Version 3,
    as published by the Free Software Foundation.

    Weave is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Weave.  If not, see <http://www.gnu.org/licenses/>.
*/

package weave.utils
{
	import flash.utils.ByteArray;
	
	import org.vanrijkom.shp.ShpHeader;
	import org.vanrijkom.shp.ShpPoint;
	import org.vanrijkom.shp.ShpPolygon;
	import org.vanrijkom.shp.ShpPolyline;
	import org.vanrijkom.shp.ShpRecord;
	import org.vanrijkom.shp.ShpTools;
	
	import weave.api.WeaveAPI;
	import weave.api.core.ILinkableObject;
	import weave.api.getCallbackCollection;
	import weave.primitives.GeneralizedGeometry;
	
	
	/**
	 * The callbacks for this object get called when all queued decoding completes.
	 * 
	 * @author adufilie
	 * @author awilkins
	 */
	public class ShpFileReader implements ILinkableObject
	{
		private var shp: ShpHeader;
		
		private var records:Array;
		private var irecord:int;
		public var geoms:Array = [];
		
		private var _processingIsDone:Boolean = false;
		public function get geomsReady():Boolean { return _processingIsDone; }
		
		public function ShpFileReader(shpData:ByteArray)
		{
			shp	= new ShpHeader(shpData);
			records = ShpTools.readRecords(shpData);
			WeaveAPI.StageUtils.startTask(this, iterate);
		}
		
		private function iterate():Number
		{
			if (irecord >= records.length) // in case length is zero
				return 1;

			var iring:int
			var ipoint:int;
			var point:ShpPoint;
			var ring:Array;
			
			//trace( irecord, records.length );
			var geom:GeneralizedGeometry = new GeneralizedGeometry();
			var points:Array = [];
			var record:ShpRecord = records[irecord] as ShpRecord;

			if( record.shape is ShpPolygon )
			{
				geom.geomType = GeneralizedGeometry.GEOM_TYPE_POLYGON;
				var poly:ShpPolygon = record.shape as ShpPolygon;
				for(iring = 0; iring < poly.rings.length; iring++ )
				{
					ring = poly.rings[iring] as Array;
					for(ipoint = 0; ipoint < ring.length; ipoint++ )
					{
						point = ring[ipoint] as ShpPoint;
						points.push( point.x, point.y );
					}
				}
			}
			if( record.shape is ShpPolyline )
				geom.geomType = GeneralizedGeometry.GEOM_TYPE_LINE;
			if( record.shape is ShpPoint )
			{
				geom.geomType = GeneralizedGeometry.GEOM_TYPE_POINT;
				point = record.shape as ShpPoint;
				points.push( point.x, point.y );
			}
			geom.setCoordinates( points, BLGTreeUtils.METHOD_SAMPLE );
			geoms.push(geom);
			
			irecord++
			
			var progress:Number = irecord / records.length;
			if (progress == 1)
			{
				_processingIsDone = true;
				getCallbackCollection(this).triggerCallbacks();
			}
			return progress;
		}
	}
}