import Chartkick from 'chartkick';
import Chart from 'chart.js/auto';
import 'chartjs-adapter-date-fns';

window.Chartkick = Chartkick;
Chartkick.addAdapter(Chart);
