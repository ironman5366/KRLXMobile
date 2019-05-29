package com.willbeddow.krlx_mobile;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.media.AudioManager;
import android.media.MediaPlayer;
import android.app.PendingIntent;
import android.net.Uri;
import android.net.wifi.WifiManager;
import android.os.AsyncTask;
import android.os.Build;
import android.os.Bundle;
import android.os.PowerManager;
import android.util.Log;

import androidx.annotation.Nullable;
import androidx.core.app.NotificationCompat;
import androidx.core.app.NotificationManagerCompat;

import com.google.android.exoplayer2.DefaultLoadControl;
import com.google.android.exoplayer2.DefaultRenderersFactory;
import com.google.android.exoplayer2.ExoPlayerFactory;
import com.google.android.exoplayer2.Player;
import com.google.android.exoplayer2.SimpleExoPlayer;
import com.google.android.exoplayer2.extractor.DefaultExtractorsFactory;
import com.google.android.exoplayer2.extractor.ExtractorsFactory;
import com.google.android.exoplayer2.source.ExtractorMediaSource;
import com.google.android.exoplayer2.source.MediaSource;
import com.google.android.exoplayer2.trackselection.AdaptiveTrackSelection;
import com.google.android.exoplayer2.trackselection.DefaultTrackSelector;
import com.google.android.exoplayer2.trackselection.TrackSelection;
import com.google.android.exoplayer2.ui.PlayerNotificationManager;
import com.google.android.exoplayer2.upstream.DataSource;
import com.google.android.exoplayer2.upstream.DefaultDataSourceFactory;
import com.google.android.exoplayer2.upstream.DefaultHttpDataSourceFactory;
import com.google.android.exoplayer2.util.Util;
import com.willbeddow.krlx_mobile.MediaHandler;

import java.net.URL;
import java.util.concurrent.atomic.AtomicInteger;

import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugins.GeneratedPluginRegistrant;


public class MainActivity extends FlutterActivity {
  private static final String CHANNEL = "krlx_mobile.willbeddow.com/media";
  private final AtomicInteger c = new AtomicInteger(0);
  SimpleExoPlayer _player;
  MediaHandler Session;
  String showName = "Unknown Show";
  String hosts = "Unknown Hosts";
  PlayerNotificationManager playerNotificationManager;
  WifiManager.WifiLock wifiLock;
  PowerManager.WakeLock wakeLock;

  int currentShowNotification;

    private class DescriptionAdapter implements
            PlayerNotificationManager.MediaDescriptionAdapter {

        @Override
        public String getCurrentContentTitle(Player player) {
            return "KRLX";
        }

        @Nullable
        @Override
        public String getCurrentContentText(Player player) {
            int window = player.getCurrentWindowIndex();
            return showName+"\n"+hosts;
        }

        @Nullable
        @Override
        public Bitmap getCurrentLargeIcon(Player player,
                                          PlayerNotificationManager.BitmapCallback callback) {
            return BitmapFactory.decodeResource(getApplicationContext().getResources(),
                    R.mipmap.ic_launcher);
        }

        @Nullable
        @Override
        public PendingIntent createCurrentContentIntent(Player player) {
            Intent intent = getPackageManager().getLaunchIntentForPackage(
                    "com.willbeddow.krlx_mobile");
            return PendingIntent.getActivity(getApplicationContext(),
                    0, intent, PendingIntent.FLAG_UPDATE_CURRENT);

        }
    }


    // TODO: override DescriptionAdapter methods to pull from KRLX data
  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    GeneratedPluginRegistrant.registerWith(this);
    this.currentShowNotification = this.c.incrementAndGet();
    playerNotificationManager = new PlayerNotificationManager(
                getApplicationContext(),
               getString(R.string.channel_id),
               this.currentShowNotification,
               new DescriptionAdapter()
             );
    this.createNotificationChannel();
    // MethodChannel to handle media notifications
    new MethodChannel(getFlutterView(), CHANNEL).setMethodCallHandler(
            (call, result) -> {
              if (call.method.equals("showNotify")){
                  showName = call.argument("showName");
                  hosts = call.argument("hosts");
                  showNotify(showName, hosts);
              }
              else if (call.method.equals("removeShowNotification")){
                  this.removeCurrentNotification();
              }
              else if (call.method.equals("play")){
                  String contentUrl = call.argument("contentUrl");
                  showName = call.argument("showName");
                  hosts = call.argument("hosts");
                  streamMusic(contentUrl);
              }
              else if (call.method.equals("pause")){
                  pauseMusic();
              }
              else{
                result.notImplemented();
              }
            }
    );
  }
    private MediaSource buildMediaSource(Uri uri) {
        return new ExtractorMediaSource.Factory(
                new DefaultHttpDataSourceFactory("KRLX-mobile")).
                createMediaSource(uri);
    }

    private SimpleExoPlayer getPlayer() {
        if (_player == null){
            _player = ExoPlayerFactory.newSimpleInstance(this);
            playerNotificationManager.setPlayer(_player);
            // omit skip previous and next actions
            playerNotificationManager.setUseNavigationActions(false);
            // omit fast forward action by setting the increment to zero
            playerNotificationManager.setFastForwardIncrementMs(0);
            // omit rewind action by setting the increment to zero
            playerNotificationManager.setRewindIncrementMs(0);
            // omit the stop action
            playerNotificationManager.setUseStopAction(false);
            playerNotificationManager.setVisibility(NotificationCompat.VISIBILITY_PUBLIC);
            playerNotificationManager.setSmallIcon(getNotificationIcon());
            playerNotificationManager.setPriority(NotificationCompat.PRIORITY_DEFAULT);
        }
        return _player;
    }

    private void streamMusic(String contentUrl){
      System.out.println("Got contentURL, playing music from stream");
      SimpleExoPlayer player = getPlayer();
      Uri uri = Uri.parse(contentUrl);
      MediaSource mediaSource = buildMediaSource(uri);
      player.prepare(mediaSource, true, false);
      player.seekTo(player.getDuration());
      player.setPlayWhenReady(true);
      NotificationManagerCompat notificationManager = NotificationManagerCompat.from(this);
      // notificationId is a unique int for each notification that you must define
      WifiManager wm = (WifiManager) getApplicationContext().getSystemService(Context.WIFI_SERVICE);
      wifiLock = wm.createWifiLock(WifiManager.WIFI_MODE_FULL_HIGH_PERF , "krlx:wifilock");
      wifiLock.acquire();
      PowerManager pm = (PowerManager) getApplicationContext().getSystemService(Context.POWER_SERVICE);
      wakeLock = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "krlx:wakelock");
      wakeLock.acquire();
      System.out.println("Started music");
  }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        if (wakeLock.isHeld())
            wakeLock.release();
        if (wifiLock.isHeld())
            wifiLock.release();
    }

    private void pauseMusic(){
      System.out.println("Pausing music");
      SimpleExoPlayer player = getPlayer();
      player.setPlayWhenReady(false);
  }
  private int getNotificationIcon() {
        boolean useWhiteIcon = (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.LOLLIPOP);
        return R.drawable.ic_stat_radio;
  }
  private void createNotificationChannel() {
        // Create the NotificationChannel, but only on API 26+ because
        // the NotificationChannel class is new and not in the support library
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            CharSequence name = getString(R.string.channel_name);
            String description = getString(R.string.channel_description);
            String channel_id = getString(R.string.channel_id);
            int importance = NotificationManager.IMPORTANCE_DEFAULT;
            NotificationChannel channel = new NotificationChannel(channel_id, name, importance);
            channel.setDescription(description);
            // Register the channel with the system; you can't change the importance
            // or other notification behaviors after this
            NotificationManager notificationManager = getSystemService(NotificationManager.class);
            notificationManager.createNotificationChannel(channel);
        }
    }

  public void removeCurrentNotification(){
    if (this.currentShowNotification != 0){
        NotificationManager mNotificationManager = (NotificationManager)
                getSystemService(NOTIFICATION_SERVICE);
        mNotificationManager.cancel(this.currentShowNotification);
    }
  }

  public void showNotify(String showName, String hosts){
      // Start a media session
      //MediaPlayer mediaPlayer = MediaPlayer.create( )
      // If currentShowNotfication exists, delete it
      this.removeCurrentNotification();
      createNotificationChannel();
      String channel_id = getString(R.string.channel_id);
      Notification showNotification = new NotificationCompat.Builder(this, channel_id)
              .setSmallIcon(getNotificationIcon())
              .setContentTitle(showName)
              .setContentText(hosts)
              .build();
      int notificationId = this.c.incrementAndGet();
      this.currentShowNotification = notificationId;
      NotificationManagerCompat notificationManager = NotificationManagerCompat.from(this);

      // notificationId is a unique int for each notification that you must define
      notificationManager.notify(notificationId, showNotification);

  }
}
