# 「しくみがわかる kubernetes」写経メモ

## CHAPTER 02 Kubernetes の環境構築

### k8s のバージョン

2020/04/22 現在 v1.16.7 が最新っぽいです。

```bash
$ az aks get-versions --location japaneast --output table
KubernetesVersion    Upgrades
-------------------  -----------------------
1.17.3(preview)      None available
1.16.7               1.17.3(preview)
1.15.10              1.16.7
1.15.7               1.15.10, 1.16.7
1.14.8               1.15.7, 1.15.10
1.14.7               1.14.8, 1.15.7, 1.15.10
```

2020/07/06 現在は v1.16.10 が最新っぽくて、1.17 も利用可能になっています。

update が早い..これについていけるのか..?

```bash
KubernetesVersion    Upgrades
-------------------  --------------------------------
1.18.4(preview)      None available
1.18.2(preview)      1.18.4(preview)
1.17.7               1.18.2(preview), 1.18.4(preview)
1.16.10              1.17.7
1.15.12              1.16.10
1.15.11              1.15.12, 1.16.10
```

c.f. https://docs.microsoft.com/en-us/azure/aks/supported-kubernetes-versions#supported-version-list

### create 時の vm の選択

本に書かれている `Snandard_DS1_v2` を指定すると怒られます。

```bash
$ az aks create --name $AKS_CLUSTER_NAME --resource-group $AKS_RES_GROUP --node-count 3 --kubernetes-version 1.16.7 --node-vm-size Standard_DS1_v2 --generate-ssh-keys --service-principal $APP_ID --client-secret $SP_PASSWD
Operation failed with status: 'Bad Request'. Details: The VM size of AgentPoolProfile:nodepool1 is not allowed in your subscription in location 'japaneast'. The available VM sizes are Standard_F16s_v2,Standard_F2s_v2,Standard_F32s_v2,Standard_F48s_v2,Standard_F4s_v2,Standard_F64s_v2,Standard_F72s_v2,Standard_F8s_v2,Standard_G1,Standard_G2,Standard_G3,Standard_G4,Standard_G5,Standard_GS1,Standard_GS2,Standard_GS3,Standard_GS4,Standard_GS4-4,Standard_GS4-8,Standard_GS5,Standard_GS5-16,Standard_GS5-8,Standard_H16,Standard_H16m,Standard_H16mr,Standard_H16r,Standard_H8,Standard_H8m,Standard_L16s,Standard_L32s,Standard_L4s,Standard_L8s,Standard_NC12s_v3,Standard_NC24rs_v3,Standard_NC24s_v3,Standard_NC6s_v3 For more details, please visit https://aka.ms/cpu-quota
```

今回は一番サイズの小さそうな `Standard_F2s_v2` を選択しました。

いずれの vm も無料枠のサブスクリプションでは実行に失敗するため、従量課金に切り替える必要がありました。

### 認証情報の設定時のコマンド間違い

`--adomin` じゃなくて `--admin` ですね。

```bash
$ az aks get-credentials --admin --resource-group $AKS_RES_GROUP --name $AKS_CLUSTER_NAME
Merged "AKSCluster-admin" as current context in /home/fukui/.kube/config
```

### `resource-group` 削除時のコマンド間違い

`-name` ではなくて `--name` 、 `$AKS_RESOURCE_GROUP` ではなくて `$AKS_RES_GROUP` ですね。

```bash
$ az group delete --name $ACR_RES_GROUP
$ az group delete --name $AKS_RES_GROUP
$ az ad sp delete --id=$(az ad sp show --id http://$SP_NAME --query appId --output tsv)
```

## CHAPTER 05 コンテナーアプリケーションの実行

P.98 (2) Pod の変更 で指定されているリスト 5.4 のファイル名が chap03/Pod/pod.yaml となっていますが、 chap05/Pod/pod.yal の誤りと思われます。

## `kubectl apply` と `kubectl create` の違い

`apply` は新規の場合は新規に作成し、更新の場合は差分適用しますが、 `create` は更新の場合にはエラーとなります。

動作の詳細は、この辺りを参考にすると良さそうです。

https://qiita.com/tkusumi/items/0bf5417c865ef716b221

## Exponential Backoff の説明

アルゴリズムの詳細について https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#restart-policy が示されていますが、内容は以下だけで、あまり細かくは書かれていません。

> # Restart policy
>
> A PodSpec has a restartPolicy field with possible values Always, OnFailure, and Never. The default value is Always. restartPolicy applies to all Containers in the Pod. restartPolicy only refers to restarts of the Containers by the kubelet on the same node. Exited Containers that are restarted by the kubelet are restarted with an exponential back-off delay (10s, 20s, 40s ...) capped at five minutes, and is reset after ten minutes of successful execution. As discussed in the Pods document, once bound to a node, a Pod will never be rebound to another node.

以下が参考になりそうです。

* https://en.wikipedia.org/wiki/Exponential_backoff

* https://yoshidashingo.hatenablog.com/entry/2014/08/17/135017
