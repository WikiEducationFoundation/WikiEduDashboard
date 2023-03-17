import React from 'react';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  BarElement,
  Title,
  Tooltip,
  Legend,
} from 'chart.js';
import { Bar } from 'react-chartjs-2';

ChartJS.register(
  CategoryScale,
  LinearScale,
  BarElement,
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


export function BarChartComponent({ year, Data, Label }) {
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
  return <Bar options={options} data={data} />;
}
