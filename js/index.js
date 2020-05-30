
import "@babel/polyfill";

import {Map, View} from 'ol';
import TileLayer from 'ol/layer/Tile';
import OSM from 'ol/source/OSM';
import {get as getProjection} from 'ol/proj';
import {WMTS} from 'ol/source';
import {default as WMTSTileGrid} from 'ol/tilegrid/WMTS';
import {Tile} from 'ol/layer';

import $ from "jquery";

require('./index.css')

$(document).ready(() => {
    console.log('ready...');

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
      url: 'https://gibs-{a-c}.earthdata.nasa.gov/wmts/epsg4326/best/wmts.cgi?TIME=2013-06-16',
      layer: 'MODIS_Terra_CorrectedReflectance_TrueColor',
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

});