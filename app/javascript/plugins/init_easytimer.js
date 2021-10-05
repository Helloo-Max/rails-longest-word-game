import Timer from "easytimer.js";

const initEasyTimer = () => {
  const timer = new Timer();
  timer.start();

  timer.addEventListener('secondsUpdated', function (e) {
      $('#basicUsage').html(timer.getTimeValues().toString());
  });
};

export { initEasyTimer }
