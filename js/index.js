
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


class AudioLooper {

    constructor(audioPath = 'mapdata/audio') {
        this.audioPath = audioPath;
        this.audio = null;
        this.currentCountry = null;
        this.currentPosition = 0.0;
        this.state = 'stop';
        this._mute = false;

        // test
        this.testFiles = [
            'accordeon_usa.ogg',
            'kalimba_ger.ogg',
            'new_age_ger.ogg',
            'tubular_bells_usa.ogg'
        ]
        this.testIdx = 0;
    }

    getAudioPath(country) {
        // test implementation
        let idx = this.testIdx;
        this.testIdx = (idx + 1) % this.testFiles.length;
        return this.audioPath + '/' + this.testFiles[idx];
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

    const source = new WMTS({
      url: 'https://gibs-{a-c}.earthdata.nasa.gov/wmts/epsg4326/best/wmts.cgi?TIME=2019-01-01',
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

    const layer = new Tile({
      source: source,
      extent: [-180, -90, 180, 90]
    });

    map.addLayer(layer);

    const vectorlayer = new VectorLayer({
      source: new VectorSource({
        format: new GeoJSON(),
        url: './mapdata/countries.geojson'
      }),
      style: defaultStyle
    })

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
});
