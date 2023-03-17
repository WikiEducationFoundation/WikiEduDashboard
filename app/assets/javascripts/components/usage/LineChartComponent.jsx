import React from 'react';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
} from 'chart.js';
import { Line } from 'react-chartjs-2';

ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend
);

const options = {
  responsive: true,
  plugins: {
    legend: {
      position: 'top',
    },
  },
};


export function LineChartComponent({ year, Data, Label }) {
  const data = {
    labels: year,
    datasets: [
      {
        id: 1,
        label: Label,
        data: Data,
        backgroundColor: 'rgba(147,173,224,255)',
      }
    ],
  };
  return <Line options={options} data={data} />;
}
