package compat;

import Xml as StdXml;

private typedef XMLImpl = #if flash flash.xml.XML #else StdXml #end;

abstract XML(XMLImpl) from XMLImpl to XMLImpl {
	public inline function new(x:String) {
		#if flash
		this = new flash.xml.XML(x);
		#else
		this = StdXml.parse(x).firstElement();
		#end
	}

	public inline function appendChild(x:XML) {
		#if flash
		this.appendChild(x);
		#else
		this.addChild(x);
		#end
	}

	public inline function attribute(name:String):String {
		#if flash
		return this.attribute(name).toString();
		#else
		var attr = this.get(name);
		return if (attr == null) "" else attr; // preserve Flash behaviour
		#end
	}

	public inline function setAttribute(name:String, value:String):String {
		#if flash
		this.attribute(name)[0] = new flash.xml.XML(value);
		#else
		this.set(name, value);
		#end
		return value;
	}

	public function child(name:String):XMLList {
		#if flash
		return this.child(name);
		#else
		return [for (x in this.elementsNamed(name)) x];
		#end
	}

	public function children():XMLList {
		#if flash
		return this.children();
		#else
		return [for (x in this.elements()) x];
		#end
	}

	public function localName():String {
		#if flash
		return this.localName();
		#else
		return this.nodeName;
		#end
	}

	public function descendants(name:String):XMLList {
		#if flash
		return this.descendants(name);
		#else
		var result = [];
		fillDescendants(this, name, result);
		return result;
		#end
	}

	#if !flash
	static function fillDescendants(x:StdXml, name:String, acc:Array<XML>) {
		for (child in x.elements()) {
			if (child.nodeName == name) {
				acc.push(child);
			}
			fillDescendants(child, name, acc);
		}
	}
	#end

	#if flash inline #end
	public function toString():String {
		#if flash
		return this.toString();
		#else
		var buf = new StringBuf();
		for (child in this) {
			if (child.nodeType == Element) {
				// if it has child elements, then it's "complex"
				return this.toString();
			} else {
				buf.add(child.nodeValue);
			}
		}
		return buf.toString();
		#end
	}

	public inline function toXMLString():String {
		#if flash
		return this.toXMLString();
		#else
		return this.toString();
		#end
	}
}
