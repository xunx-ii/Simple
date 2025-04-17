// Fill out your copyright notice in the Description page of Project Settings.


#include "Abilities/AttributeSets/SimpleAttributeSet.h"
#include "Abilities/SimpleAbilitySystemComponent.h"

USimpleAttributeSet::USimpleAttributeSet()
{

}

USimpleAbilitySystemComponent* USimpleAttributeSet::GetSimpleAbilitySystemComponent() const
{
	return Cast<USimpleAbilitySystemComponent>(GetOwningAbilitySystemComponent());
}
