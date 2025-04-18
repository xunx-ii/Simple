// Fill out your copyright notice in the Description page of Project Settings.


#include "UI/SimplePrimaryLayout.h"


USimplePrimaryLayout::USimplePrimaryLayout(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
	
}

void USimplePrimaryLayout::FindAndRemoveWidgetFromLayer(UCommonActivatableWidget* ActivatableWidget)
{
	for (const auto& LayerKVP : Layers)
	{
		LayerKVP.Value->RemoveWidget(*ActivatableWidget);
	}
}

UCommonActivatableWidgetContainerBase* USimplePrimaryLayout::GetLayerWidget(FGameplayTag LayerName)
{
	return Layers.FindRef(LayerName);
}

void USimplePrimaryLayout::RegisterLayer(FGameplayTag LayerTag, UCommonActivatableWidgetContainerBase* LayerWidget)
{
	if (!IsDesignTime())
	{
		LayerWidget->SetTransitionDuration(0.0);
		Layers.Add(LayerTag, LayerWidget);
	}
}
