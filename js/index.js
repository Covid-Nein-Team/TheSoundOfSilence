
import "@babel/polyfill";

import {Map, View} from 'ol';
import VectorLayer from 'ol/layer/Vector';
import VectorSource from 'ol/source/Vector';
import GeoJSON from 'ol/format/GeoJSON';
import {get as getProjection} from 'ol/proj';
import {WMTS} from 'ol/source';
import {default as WMTSTileGrid} from 'ol/tilegrid/WMTS';
import {Tile} from 'ol/layer';
import Style from 'ol/style/Style';
import Fill from 'ol/style/Fill';
import Stroke from 'ol/style/Stroke';

import $ from "jquery";

require('./index.css')

function countryCase(str) {
  str = str.toLowerCase().split(' ');
  for (var i = 0; i < str.length; i++) {
    str[i] = str[i].charAt(0).toUpperCase() + str[i].slice(1);
  }
  return str.join('_') + '.ogg';
}


class AudioLooper {

    constructor(audioPath = 'mapdata/mixed') {
        this.audioPath = audioPath;
        this.audio = null;
        this.currentCountry = null;
        this.currentPosition = 0.0;
        this.state = 'stop';
        this._mute = false;

    }

    getAudioPath(country) {
        // test implementation
        return this.audioPath + '/' + countryCase(country);
    }

    setCountry(country = null) {
        if (country === null || country === undefined || country.length === 0) {
            this.stop();
            this.state = 'stop';
            this.currentCountry = country;
            return;
        }
        if (this.state !== 'stop' && country === this.currentCountry) {
            return;
        }
        this.stop();
        this.state = 'playing';
        this.currentCountry = country;
        this.audio = new Audio(this.getAudioPath(country));
        this.audio.loop = true;
        this.audio.currentTime = this.currentPosition;
        this.audio.addEventListener("timeupdate", () => {
            this.currentPosition = this.audio.currentTime;
            let v = this.audio.currentTime / this.audio.duration;
            if (v) {
                if (window.updateSliderFraction) {
                    window.updateSliderFraction(v);
                }
            }
        });
        if (!this._mute) {
            this.play();
        }
    }

    stop() {
        try {
            this.audio.pause();
        } catch (error) {
            if (this.audio === null) {
                // harmless
            } else {
                console.log('pause threw error?', error);
            }
        }
    }

    play() {
        this.audio.play().catch(error => {
            if (error.code === 20) {
                // harmless
            } else {
                console.error(error);
            }
        });
    }

    mute(state) {
        console.log('audiolooper', state);
        if (state) {
            this._mute = true;
            this.stop()
        } else {
            this._mute = false;
        }
    }

}

window.audioLooper = new AudioLooper();


function addDays(date, days) {
    let result = new Date(date);
    result.setDate(result.getDate() + days);
    return result;
}

function getDay(index) {
    // okay, there's not enough time to get all of this working
    // cutting a few corners :P here
    index = index % 160;
    let start = new Date('2019-12-01');
    let current = addDays(start, index);
    return current.toISOString().split('T')[0];
}

window.spaceAppsGetDay = getDay;

function createNewTileLayer(dayString) {

    const source = new WMTS({
        url: 'https://gibs-{a-c}.earthdata.nasa.gov/wmts/epsg4326/best/wmts.cgi?TIME=' + dayString,
        layer: 'VIIRS_SNPP_CorrectedReflectance_TrueColor',
        format: 'image/jpeg',
        matrixSet: 'EPSG4326_250m',
        tileGrid: new WMTSTileGrid({
            origin: [-180, 90],
            resolutions: [
                0.5625,
                0.28125,
                0.140625,
                0.0703125,
                0.03515625,
                0.017578125,
                0.0087890625,
                0.00439453125,
                0.002197265625
            ],
            matrixIds: [0, 1, 2, 3, 4, 5, 6, 7, 8],
            tileSize: 512
        })
    });

    return new Tile({
        source: source,
        extent: [-180, -90, 180, 90]
    });
}

// FAKE time playback.
// there's not enough time to have this synchronized to audio playback
// in a realistic way. need to get this out in about 25minutes...
class TileLayerPlayback {

    constructor(map, bufferlength=10, timeout=500) {
        this._map = map;

        this.buffer = [];

        for (let i = 0; i < bufferlength; i++) {
            let layer = createNewTileLayer(getDay(i));
            this.buffer.push(layer);
            layer.setZIndex(bufferlength - i);
            this._map.addLayer(layer);
        }
        this.index = bufferlength - 1;
        this.timeout = timeout;

        this._should_stop = false;
        this._cb_ref = null;
    }

    play() {
        this._should_stop = false;
        this._playloop();
    }

    stop() {
        this._should_stop = true;
        if (this._cb_ref) {
            clearTimeout(this._cb_ref);
            this._cb_ref = null;
        }
    }

    _playloop() {
        if (this._should_stop) {
            this._should_stop = false;
            if (this._cb_ref) {
                clearTimeout(this._cb_ref);
                this._cb_ref = null;
            }
        } else {
            this.cycleLayer();
            this._cb_ref = setTimeout(() => this._playloop(), this.timeout);
        }
    }

    cycleLayer() {
        // remove old layer
        let oldLayer = this.buffer.shift();
        oldLayer.setZIndex(-this.buffer.length);
        this._map.removeLayer(oldLayer);

        // reassign z index
        for (let i = 0; i < this.buffer.length; i++) {
            this.buffer[i].setZIndex(this.buffer.length - i)
        }

        // add new layer
        this.index += 1;
        let newLayer = createNewTileLayer(getDay(this.index));
        this.buffer.push(newLayer);
        newLayer.setZIndex(0);
        this._map.addLayer(newLayer);
    }

}


$(document).ready(() => {
    console.log('ready...');

    const defaultStyle = new Style({
        fill: new Fill({
            color: 'rgba(255, 255, 255, 0.0)'
        }),
        stroke: new Stroke({
            color: 'rgba(33,33,33, 0.8)',
            width: 1
        })
    });
    const highlightStyle = new Style({
      fill: new Fill({
        color: 'rgba(215, 25, 28, 0.7)'
      }),
      stroke: new Stroke({
        color: 'rgba(33,33,33, 0.8)',
        width: 1
      })
    });

    const map = new Map({
      view: new View({
        projection: getProjection('EPSG:4326'),
        extent: [-180, -90, 180, 90],
        center: [0, 0],
        zoom: 3,
        minZoom: 2,
        maxZoom: 8
      }),
      target: 'earth-map',
      renderer: ['canvas', 'dom']
    });

    window.tileLayerPlayback = new TileLayerPlayback(map, 6);

    const vectorlayer = new VectorLayer({
      source: new VectorSource({
        format: new GeoJSON(),
        url: './mapdata/countries.geojson'
      }),
      style: defaultStyle
    })
    vectorlayer.setZIndex(100);

    map.addLayer(vectorlayer);

    let selectedName = null;
    let selected = null;
    map.on('pointermove', function(e) {
      if (selected !== null) {
          selected.setStyle(defaultStyle);
          selected = null;
      }
      map.forEachFeatureAtPixel(e.pixel, function(f) {
          selected = f;
          f.setStyle(highlightStyle);
          return true;
      });
      if (selected) {
          let newName = selected.get('name');
          if (newName !== selectedName) {
              Shiny.onInputChange('hoverCountry', newName);
              selectedName = newName;
              window.audioLooper.setCountry(newName);
          }
      } else {
          selectedName = '';
          window.audioLooper.setCountry();
      }
    });

    $('a[data-toggle=offcanvas]').click(() => {
        setTimeout( function() { map.updateSize();}, 200);
    });
    window.onresize = function() {
        setTimeout( function() { map.updateSize();}, 200);
    }

    function updateSliderFraction(val) {
        let dateSlider = $("#currentDay");
        let iDateSlider = jQuery.data(dateSlider[0]).ionRangeSlider;
        if (iDateSlider) {
            let a = iDateSlider.options.min;
            let b = iDateSlider.options.max;
            let v = parseInt((b - a) * val + a);
            iDateSlider.update({from: v});
        } else {
            console.log('???');
        }
    }
    window.updateSliderFraction = updateSliderFraction
});
